import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The system keychain is unavailable or rejected the operation. Without the
/// key the encrypted DB can't be opened (by design there's no insecure
/// fallback): the backup is to export `.jwpp` regularly.
class DbKeyException implements Exception {
  const DbKeyException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// The password failed to unwrap the DB key (AES-GCM tag mismatch). Distinct
/// from [DbKeyException] so the UI can say "wrong password" instead of
/// "keychain broken".
class WrongPasswordException implements Exception {
  const WrongPasswordException();
}

/// Where the local account key material lives. Injectable so unit tests can
/// use an in-memory map (FlutterSecureStorage needs platform channels).
abstract interface class SecureKeyStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class KeychainKeyStore implements SecureKeyStore {
  const KeychainKeyStore();

  // macOS: classic keychain — the data-protection keychain requires a
  // provisioning profile (keychain-access-groups entitlement), unavailable
  // when signing with a development certificate only.
  static const _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

enum LocalKeyStatus {
  /// No key material at all: fresh install → create-account wizard.
  none,

  /// Plaintext DEK from an install that predates the local account: force
  /// the migration wizard (wrap it with a new password).
  legacyPlaintext,

  /// DEK wrapped with the account password: show the unlock screen.
  wrapped,
}

/// Argon2id cost parameters (OWASP Password Storage Cheat Sheet). They are
/// stored inside every wrapped blob, so they can be tuned later without a
/// data migration: old blobs keep unlocking with the params they were
/// created with.
class KdfParams {
  const KdfParams({
    required this.memoryKib,
    required this.iterations,
    required this.parallelism,
  });

  static const owasp =
      KdfParams(memoryKib: 19456, iterations: 2, parallelism: 1);

  final int memoryKib;
  final int iterations;
  final int parallelism;
}

/// DB encryption key manager (envelope encryption).
///
/// A random 256-bit DEK encrypts the drift database (sqlite3mc). The DEK is
/// wrapped with AES-256-GCM under a KEK derived from the local account
/// password via Argon2id. A successful unwrap (the GCM tag verifies) IS the
/// password check — no separate hash is stored. Losing the password loses
/// the data: there is deliberately no recovery path.
class DbKeyManager {
  DbKeyManager({SecureKeyStore? store, this.params = KdfParams.owasp})
      : _store = store ?? const KeychainKeyStore();

  final SecureKeyStore _store;

  /// KDF cost for NEW blobs (unlocking reads the cost from the blob itself).
  final KdfParams params;

  /// Plaintext DEK hex written by pre-account versions of the app.
  static const legacyKeyName = 'jw_program.db_key.v1';

  /// JSON blob `{v, kdf, m, t, p, salt, nonce, ct, mac}` (base64 fields).
  static const wrappedKeyName = 'jw_program.db_key.v2';

  Future<LocalKeyStatus> status() async {
    try {
      final wrapped = await _store.read(wrappedKeyName);
      final legacy = await _store.read(legacyKeyName);
      if (wrapped != null) {
        // Crash window between write-v2 and delete-v1: the wrapped blob was
        // verified before the delete was attempted, so finish the migration.
        if (legacy != null) await _store.delete(legacyKeyName);
        return LocalKeyStatus.wrapped;
      }
      if (legacy != null && legacy.length == 64) {
        return LocalKeyStatus.legacyPlaintext;
      }
      return LocalKeyStatus.none;
    } catch (e) {
      throw DbKeyException('Could not access the system keychain. ($e)', e);
    }
  }

  /// Fresh install: generate a new DEK and wrap it with [password].
  /// Returns the DEK hex, ready to open the database.
  Future<String> createAccount(String password) async {
    final dekHex = _randomHex(32);
    await _writeWrapped(dekHex, password);
    return dekHex;
  }

  /// Unwrap the DEK with [password]. Throws [WrongPasswordException] when the
  /// password is wrong, [DbKeyException] when no blob exists or the keychain
  /// fails.
  Future<String> unlock(String password) async {
    final String? blob;
    try {
      blob = await _store.read(wrappedKeyName);
    } catch (e) {
      throw DbKeyException('Could not access the system keychain. ($e)', e);
    }
    if (blob == null) {
      throw const DbKeyException(
          'No local account key found in the system keychain.');
    }
    return _unwrap(blob, password);
  }

  /// Wrap the pre-existing plaintext DEK with [password]. The legacy entry is
  /// deleted only after the wrapped blob has been written AND verified, so an
  /// abandoned wizard or a crash never loses the key.
  Future<String> migrateLegacy(String password) async {
    final String? dekHex;
    try {
      dekHex = await _store.read(legacyKeyName);
    } catch (e) {
      throw DbKeyException('Could not access the system keychain. ($e)', e);
    }
    if (dekHex == null || dekHex.length != 64) {
      throw const DbKeyException(
          'No legacy database key found to migrate.');
    }
    await _writeWrapped(dekHex, password);
    try {
      await _store.delete(legacyKeyName);
    } catch (_) {
      // Non-fatal: status() completes the deletion on the next launch.
    }
    return dekHex;
  }

  /// Re-wrap the same DEK under a new password (fresh salt + nonce). The
  /// database itself is never re-encrypted. Throws [WrongPasswordException]
  /// if [current] is wrong.
  Future<void> changePassword(String current, String next) async {
    final dekHex = await unlock(current);
    await _writeWrapped(dekHex, next);
  }

  /// Delete all key material. The encrypted DB file becomes unreadable
  /// forever; callers must also delete the DB file ("forgot password" reset).
  Future<void> destroyAll() async {
    try {
      await _store.delete(wrappedKeyName);
      await _store.delete(legacyKeyName);
    } catch (e) {
      throw DbKeyException('Could not access the system keychain. ($e)', e);
    }
  }

  /// Wrap + persist + verify. Some platforms fail keychain writes SILENTLY
  /// (e.g. macOS signed wrong), so the blob is read back and unwrapped before
  /// anything gets encrypted with the DEK.
  Future<void> _writeWrapped(String dekHex, String password) async {
    final blob = await _wrap(dekHex, password);
    final String? verified;
    try {
      await _store.write(wrappedKeyName, blob);
      verified = await _store.read(wrappedKeyName);
    } catch (e) {
      throw DbKeyException('Could not access the system keychain. ($e)', e);
    }
    if (verified != blob) {
      throw const DbKeyException(
          'The system keychain did not persist the database key. '
          'The local database cannot be protected.');
    }
    final roundTrip = await _unwrap(blob, password);
    if (roundTrip != dekHex) {
      throw const DbKeyException(
          'Key wrap verification failed; refusing to continue.');
    }
  }

  Future<String> _wrap(String dekHex, String password) async {
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final kek = await _deriveKek(password, salt, params);
    final box = await AesGcm.with256bits().encrypt(
      _hexToBytes(dekHex),
      secretKey: SecretKey(kek),
      nonce: nonce,
    );
    return jsonEncode({
      'v': 2,
      'kdf': 'argon2id',
      'm': params.memoryKib,
      't': params.iterations,
      'p': params.parallelism,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ct': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  Future<String> _unwrap(String blobJson, String password) async {
    final KdfParams blobParams;
    final List<int> salt, nonce, ct, mac;
    try {
      final blob = jsonDecode(blobJson) as Map<String, dynamic>;
      blobParams = KdfParams(
        memoryKib: blob['m'] as int,
        iterations: blob['t'] as int,
        parallelism: blob['p'] as int,
      );
      salt = base64Decode(blob['salt'] as String);
      nonce = base64Decode(blob['nonce'] as String);
      ct = base64Decode(blob['ct'] as String);
      mac = base64Decode(blob['mac'] as String);
    } catch (e) {
      throw DbKeyException('The stored key blob is corrupted. ($e)', e);
    }
    final kek = await _deriveKek(password, salt, blobParams);
    try {
      final dek = await AesGcm.with256bits().decrypt(
        SecretBox(ct, nonce: nonce, mac: Mac(mac)),
        secretKey: SecretKey(kek),
      );
      return _bytesToHex(dek);
    } on SecretBoxAuthenticationError {
      throw const WrongPasswordException();
    }
  }

  /// Argon2id in this package is pure Dart and takes on the order of a
  /// second at OWASP cost: run it off the UI isolate.
  static Future<List<int>> _deriveKek(
      String password, List<int> salt, KdfParams params) {
    final m = params.memoryKib;
    final t = params.iterations;
    final p = params.parallelism;
    return Isolate.run(() async {
      final algorithm = Argon2id(
        parallelism: p,
        memory: m,
        iterations: t,
        hashLength: 32,
      );
      final key = await algorithm.deriveKeyFromPassword(
          password: password, nonce: salt);
      return key.extractBytes();
    });
  }

  static List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  static String _randomHex(int byteLength) =>
      _bytesToHex(_randomBytes(byteLength));

  static String _bytesToHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static List<int> _hexToBytes(String hex) => List<int>.generate(
      hex.length ~/ 2, (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16));
}
