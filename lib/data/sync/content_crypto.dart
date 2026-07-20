import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// The payload could not be decrypted (wrong key, tampered blob, or a doc
/// moved to another path — the AAD binds it to `cid/entityId`).
class ContentDecryptException implements Exception {
  const ContentDecryptException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The blob is fine — we just don't hold that key version yet, because a
/// rotation happened elsewhere and this device hasn't caught up.
///
/// A SUBCLASS so every existing `catch (ContentDecryptException)` keeps
/// working, but the sync engine can tell the two apart: a corrupt blob is
/// permanent (skip it, move the cursor on), an unknown version is transient
/// (holding the cursor is the only thing that stops those docs from being
/// skipped FOREVER once the cursor passes them).
class UnknownKeyVersionException extends ContentDecryptException {
  const UnknownKeyVersionException(this.keyVersion)
      : super('Unknown content key version.');

  final int keyVersion;

  @override
  String toString() => 'Unknown content key version $keyVersion.';
}

/// Per-congregation content keys (docs/DATA_ARCHITECTURE.md §5): synced
/// payloads are AES-256-GCM blobs under the congregation's key. The keyring
/// holds every key version this member knows — revocation adds a NEW
/// version for future writes instead of re-encrypting history.
class CongregationKeyring {
  CongregationKeyring(this.keys)
      : assert(keys.isNotEmpty, 'a keyring needs at least one key');

  /// version → 32-byte key. Versions only grow.
  final Map<int, List<int>> keys;

  int get currentVersion =>
      keys.keys.reduce((a, b) => a > b ? a : b);

  List<int> get currentKey => keys[currentVersion]!;

  static List<int> newKey() {
    final rnd = Random.secure();
    return List<int>.generate(32, (_) => rnd.nextInt(256));
  }
}

/// Encrypts/decrypts sync payloads. Envelope: `base64(nonce|ct|mac)` with
/// AAD = `cid/entityId`, so a blob replayed under another entity or
/// congregation fails authentication.
class ContentCrypto {
  static final _aes = AesGcm.with256bits();

  static List<int> _aad(String congregationId, String entityId) =>
      utf8.encode('$congregationId/$entityId');

  Future<String> encrypt({
    required CongregationKeyring keyring,
    required String congregationId,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final box = await _aes.encrypt(
      utf8.encode(jsonEncode(payload)),
      secretKey: SecretKey(keyring.currentKey),
      aad: _aad(congregationId, entityId),
    );
    return base64Encode(box.concatenation());
  }

  Future<Map<String, dynamic>> decrypt({
    required CongregationKeyring keyring,
    required int keyVersion,
    required String congregationId,
    required String entityId,
    required String blob,
  }) async {
    final key = keyring.keys[keyVersion];
    if (key == null) throw UnknownKeyVersionException(keyVersion);
    final SecretBox box;
    try {
      box = SecretBox.fromConcatenation(
        Uint8List.fromList(base64Decode(blob)),
        nonceLength: 12,
        macLength: 16,
      );
    } catch (e) {
      throw ContentDecryptException('Malformed sync blob. ($e)');
    }
    try {
      final clear = await _aes.decrypt(
        box,
        secretKey: SecretKey(key),
        aad: _aad(congregationId, entityId),
      );
      return jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
    } on SecretBoxAuthenticationError {
      throw const ContentDecryptException(
          'Sync blob failed authentication (wrong key or tampered doc).');
    }
  }
}
