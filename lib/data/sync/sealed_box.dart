import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../crypto/passphrase_envelope.dart' show PassphraseEnvelope;

/// The box could not be opened: wrong recipient key, tampered box or a
/// malformed map. Deliberately one exception — callers can't fix any of it.
class SealedBoxException implements Exception {
  const SealedBoxException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Anonymous public-key encryption of a small secret (a CCK) to an X25519
/// public key: ephemeral keypair → ECDH → HKDF-SHA256 → AES-256-GCM.
/// The HKDF info binds the derived key to both public keys, so a box can't
/// be replayed against a different recipient.
///
/// Private keys are handled as 32-byte seeds ([X25519.newKeyPairFromSeed]),
/// so storing the seed re-derives the public key.
abstract final class SealedBox {
  static const _info = 'agora.cck.v1';

  static final _x25519 = X25519();
  static final _aes = AesGcm.with256bits();

  static Future<List<int>> _wrapKey(
    SecretKey shared,
    List<int> ephemeralPub,
    List<int> recipientPub,
  ) {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    return hkdf
        .deriveKey(
          secretKey: shared,
          info: [...utf8.encode(_info), ...ephemeralPub, ...recipientPub],
        )
        .then((k) => k.extractBytes());
  }

  /// Encrypts [secret] to [recipientPubKey] (32 raw bytes). Returns the box
  /// map `{v, epk, nonce, ct, mac}` (base64 fields), JSON/Firestore-ready.
  static Future<Map<String, String>> seal(
    List<int> secret,
    List<int> recipientPubKey,
  ) async {
    final ephemeral = await _x25519.newKeyPair();
    final ephemeralPub = (await ephemeral.extractPublicKey()).bytes;
    final shared = await _x25519.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey:
          SimplePublicKey(recipientPubKey, type: KeyPairType.x25519),
    );
    final nonce = PassphraseEnvelope.randomBytes(12);
    final box = await _aes.encrypt(
      secret,
      secretKey: SecretKey(await _wrapKey(shared, ephemeralPub, recipientPubKey)),
      nonce: nonce,
    );
    return {
      'v': '1',
      'epk': base64Encode(ephemeralPub),
      'nonce': base64Encode(nonce),
      'ct': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
  }

  /// Opens a [seal]ed box with the recipient's 32-byte private seed.
  static Future<List<int>> open(
    Map<String, dynamic> box,
    List<int> recipientSeed,
  ) async {
    final List<int> ephemeralPub, nonce, ct, mac;
    try {
      ephemeralPub = base64Decode(box['epk'] as String);
      nonce = base64Decode(box['nonce'] as String);
      ct = base64Decode(box['ct'] as String);
      mac = base64Decode(box['mac'] as String);
    } catch (e) {
      throw SealedBoxException('Malformed sealed box. ($e)', e);
    }
    final keyPair = await _x25519.newKeyPairFromSeed(recipientSeed);
    final recipientPub = (await keyPair.extractPublicKey()).bytes;
    final shared = await _x25519.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: SimplePublicKey(ephemeralPub, type: KeyPairType.x25519),
    );
    try {
      return await _aes.decrypt(
        SecretBox(ct, nonce: nonce, mac: Mac(mac)),
        secretKey: SecretKey(await _wrapKey(shared, ephemeralPub, recipientPub)),
      );
    } on SecretBoxAuthenticationError catch (e) {
      throw SealedBoxException('Sealed box authentication failed.', e);
    }
  }

  /// Public key (32 raw bytes) for a stored private seed.
  static Future<List<int>> publicKeyOf(List<int> seed) async =>
      (await _x25519.newKeyPairFromSeed(seed)).extractPublicKey().then((k) => k.bytes);
}
