import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../crypto/passphrase_envelope.dart';

export '../crypto/passphrase_envelope.dart' show KdfParams;

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

  /// Every key this app stored. Needed to wipe uid-scoped entries (the sync
  /// identity seed and per-congregation keys) whose exact names aren't known
  /// at reset time.
  Future<Set<String>> keys();
}

class KeychainKeyStore implements SecureKeyStore {
  const KeychainKeyStore();

  // macOS: classic keychain — the data-protection keychain requires a
  // provisioning profile (keychain-access-groups entitlement), unavailable
  // when signing with a development certificate only. accessibility must be
  // null: modern macOS rejects kSecAttrAccessible on the file-based keychain
  // with errSecMissingEntitlement (-34018) on every write.
  static const _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(
      accessibility: null,
      usesDataProtectionKeychain: false,
    ),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<Set<String>> keys() async => (await _storage.readAll()).keys.toSet();
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

  /// Cloud-mode device key: plaintext DEK hex. In cloud mode the Firebase
  /// session is the gate, so the key is only protected by the OS keychain.
  static const cloudKeyName = 'jw_program.db_key.cloud.v1';

  /// Local-mode device-unlock copy: plaintext DEK hex, written only while the
  /// user has biometric/device unlock enabled. The password-wrapped blob stays
  /// the source of truth; this copy trades the password gate for the OS
  /// keychain gate (same trust level as [cloudKeyName]) so Touch ID / Face ID
  /// / fingerprint can release the key without the password.
  static const deviceUnlockKeyName = 'jw_program.db_key.device_unlock.v1';

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
        'No local account key found in the system keychain.',
      );
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
      throw const DbKeyException('No legacy database key found to migrate.');
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

  /// Cloud mode: DEK generated once per device, kept plaintext in the
  /// keychain. Reuses the verify-read-back defense against silent writes.
  Future<String> getOrCreateCloudKeyHex() async {
    try {
      final existing = await _store.read(cloudKeyName);
      if (existing != null && existing.length == 64) return existing;

      final hex = _randomHex(32);
      await _store.write(cloudKeyName, hex);
      final verified = await _store.read(cloudKeyName);
      if (verified != hex) {
        throw const DbKeyException(
          'The system keychain did not persist the database key. '
          'The local database cannot be protected.',
        );
      }
      return hex;
    } on DbKeyException {
      rethrow;
    } catch (e) {
      throw DbKeyException('Could not access the system keychain. ($e)', e);
    }
  }

  /// Local mode: persist the DEK copy that device auth releases. Reuses the
  /// verify-read-back defense against silent keychain writes.
  Future<void> enableDeviceUnlock(String dekHex) async {
    try {
      await _store.write(deviceUnlockKeyName, dekHex);
      final verified = await _store.read(deviceUnlockKeyName);
      if (verified != dekHex) {
        throw const DbKeyException(
          'The system keychain did not persist the device-unlock key.',
        );
      }
    } on DbKeyException {
      rethrow;
    } catch (e) {
      throw DbKeyException('Could not access the system keychain. ($e)', e);
    }
  }

  /// DEK hex behind device unlock, or null when the copy is gone (disabled,
  /// or the keychain lost it): callers fall back to the password.
  Future<String?> readDeviceUnlockKey() async {
    try {
      final hex = await _store.read(deviceUnlockKeyName);
      return (hex != null && hex.length == 64) ? hex : null;
    } catch (e) {
      throw DbKeyException('Could not access the system keychain. ($e)', e);
    }
  }

  Future<void> disableDeviceUnlock() async {
    try {
      await _store.delete(deviceUnlockKeyName);
    } catch (e) {
      throw DbKeyException('Could not access the system keychain. ($e)', e);
    }
  }

  /// Namespace of the E2E sync key material (identity seed + per-congregation
  /// keyrings). Those names embed the uid, so a wipe has to match by prefix.
  static const syncKeyPrefix = 'jw_program.sync.';

  /// Delete all key material — the DB keys AND every sync key of every
  /// account that used this device. The encrypted DB file becomes unreadable
  /// forever; callers must also delete the DB file ("forgot password" reset).
  Future<void> destroyAll() async {
    try {
      await _store.delete(wrappedKeyName);
      await _store.delete(legacyKeyName);
      await _store.delete(cloudKeyName);
      await _store.delete(deviceUnlockKeyName);
      for (final key in await _store.keys()) {
        if (key.startsWith(syncKeyPrefix)) await _store.delete(key);
      }
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
        'The local database cannot be protected.',
      );
    }
    final roundTrip = await _unwrap(blob, password);
    if (roundTrip != dekHex) {
      throw const DbKeyException(
        'Key wrap verification failed; refusing to continue.',
      );
    }
  }

  // Envelope shared with the sync key bootstrap (lib/data/crypto/); the
  // local-account blob keeps its historical `v: 2` tag.
  PassphraseEnvelope get _envelope => PassphraseEnvelope(params: params);

  Future<String> _wrap(String dekHex, String password) =>
      _envelope.wrap(_hexToBytes(dekHex), password, version: 2);

  Future<String> _unwrap(String blobJson, String password) async {
    try {
      return _bytesToHex(await _envelope.unwrap(blobJson, password));
    } on WrongPassphraseException {
      throw const WrongPasswordException();
    } on CorruptEnvelopeException catch (e) {
      throw DbKeyException(e.message, e.cause);
    }
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
    hex.length ~/ 2,
    (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
  );
}
