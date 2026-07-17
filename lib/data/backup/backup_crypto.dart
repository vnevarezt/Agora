import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// The password failed to open the backup (GCM tag mismatch).
class WrongBackupPasswordException implements Exception {
  const WrongBackupPasswordException();
}

/// The file is not an Agora backup (or is corrupted).
class MalformedBackupException implements Exception {
  const MalformedBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Password envelope for `.agora` backup files: Argon2id (OWASP cost, same
/// as DbKeyManager) derives the key, AES-256-GCM seals the JSON payload.
/// The envelope is itself JSON with a magic header, so a wrong file fails
/// loudly instead of prompting for a password.
class BackupCrypto {
  static const _magic = 'agora-backup';
  static const _memoryKib = 19456;
  static const _iterations = 2;
  static const _parallelism = 1;

  static Future<Uint8List> seal(
      Map<String, dynamic> payload, String password) async {
    final rnd = Random.secure();
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    final nonce = List<int>.generate(12, (_) => rnd.nextInt(256));
    final key = await _deriveKey(password, salt, _memoryKib, _iterations,
        _parallelism);
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(jsonEncode(payload)),
      secretKey: SecretKey(key),
      nonce: nonce,
    );
    return utf8.encode(jsonEncode({
      'magic': _magic,
      'v': 1,
      'kdf': 'argon2id',
      'm': _memoryKib,
      't': _iterations,
      'p': _parallelism,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ct': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    }));
  }

  static Future<Map<String, dynamic>> open(
      Uint8List bytes, String password) async {
    final Map<String, dynamic> envelope;
    final List<int> salt, nonce, ct, mac;
    final int m, t, p;
    try {
      envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (envelope['magic'] != _magic) {
        throw const MalformedBackupException(
            'The file is not an Agora backup.');
      }
      m = envelope['m'] as int;
      t = envelope['t'] as int;
      p = envelope['p'] as int;
      salt = base64Decode(envelope['salt'] as String);
      nonce = base64Decode(envelope['nonce'] as String);
      ct = base64Decode(envelope['ct'] as String);
      mac = base64Decode(envelope['mac'] as String);
    } on MalformedBackupException {
      rethrow;
    } catch (e) {
      throw MalformedBackupException('Unreadable backup file. ($e)');
    }
    final key = await _deriveKey(password, salt, m, t, p);
    try {
      final clear = await AesGcm.with256bits().decrypt(
        SecretBox(ct, nonce: nonce, mac: Mac(mac)),
        secretKey: SecretKey(key),
      );
      return jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
    } on SecretBoxAuthenticationError {
      throw const WrongBackupPasswordException();
    }
  }

  /// Argon2id in pure Dart takes ~1 s at OWASP cost: off the UI isolate
  /// (same rationale as DbKeyManager).
  static Future<List<int>> _deriveKey(
      String password, List<int> salt, int m, int t, int p) {
    return Isolate.run(() async {
      final key = await Argon2id(
        parallelism: p,
        memory: m,
        iterations: t,
        hashLength: 32,
      ).deriveKeyFromPassword(password: password, nonce: salt);
      return key.extractBytes();
    });
  }
}
