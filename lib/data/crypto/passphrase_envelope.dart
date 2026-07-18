import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// The passphrase failed to open the envelope (AES-GCM tag mismatch).
class WrongPassphraseException implements Exception {
  const WrongPassphraseException();
}

/// The stored envelope JSON is malformed (not a passphrase problem).
class CorruptEnvelopeException implements Exception {
  const CorruptEnvelopeException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
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

  static const owasp = KdfParams(
    memoryKib: 19456,
    iterations: 2,
    parallelism: 1,
  );

  final int memoryKib;
  final int iterations;
  final int parallelism;
}

/// Wraps a small secret under a passphrase: AES-256-GCM under a KEK derived
/// with Argon2id. A successful unwrap (the GCM tag verifies) IS the
/// passphrase check — no separate hash is stored. Blob JSON:
/// `{v, kdf, m, t, p, salt, nonce, ct, mac}` (base64 fields).
///
/// Used by [DbKeyManager] for the local-account DEK (v: 2) and by the sync
/// key bootstrap for the X25519 seed in `users/{uid}` (v: 1).
class PassphraseEnvelope {
  const PassphraseEnvelope({this.params = KdfParams.owasp});

  /// KDF cost for NEW blobs (unwrapping reads the cost from the blob).
  final KdfParams params;

  Future<String> wrap(
    List<int> secret,
    String passphrase, {
    int version = 1,
  }) async {
    final salt = randomBytes(16);
    final nonce = randomBytes(12);
    final kek = await _deriveKek(passphrase, salt, params);
    final box = await AesGcm.with256bits().encrypt(
      secret,
      secretKey: SecretKey(kek),
      nonce: nonce,
    );
    return jsonEncode({
      'v': version,
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

  /// Throws [WrongPassphraseException] when the passphrase is wrong,
  /// [CorruptEnvelopeException] when the blob doesn't parse.
  Future<List<int>> unwrap(String blobJson, String passphrase) async {
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
      throw CorruptEnvelopeException('The stored key blob is corrupted. ($e)', e);
    }
    final kek = await _deriveKek(passphrase, salt, blobParams);
    try {
      return await AesGcm.with256bits().decrypt(
        SecretBox(ct, nonce: nonce, mac: Mac(mac)),
        secretKey: SecretKey(kek),
      );
    } on SecretBoxAuthenticationError {
      throw const WrongPassphraseException();
    }
  }

  /// Argon2id in this package is pure Dart and takes on the order of a
  /// second at OWASP cost: run it off the UI isolate.
  static Future<List<int>> _deriveKek(
    String passphrase,
    List<int> salt,
    KdfParams params,
  ) {
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
        password: passphrase,
        nonce: salt,
      );
      return key.extractBytes();
    });
  }

  static List<int> randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }
}
