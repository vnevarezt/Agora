import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart' show DartSha256;

import '../crypto/passphrase_envelope.dart' show PassphraseEnvelope;

/// Why a link payload couldn't be read. Distinguishable so the UI can tell
/// "you pasted half of it" from "that's not an Agora code".
enum LinkPayloadError { badPrefix, badVersion, truncated, badChecksum }

class LinkPayloadException implements Exception {
  const LinkPayloadException(this.error);

  final LinkPayloadError error;

  @override
  String toString() => 'LinkPayloadException(${error.name})';
}

/// The box could not be opened: wrong session, wrong secret, or tampering.
class DeviceLinkException implements Exception {
  const DeviceLinkException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// What the NEW device shows (as text and QR) and the EXISTING device reads.
///
/// It carries the ephemeral public key **out of band** — that is the whole
/// security argument: the existing device seals the identity seed to a key it
/// read from the screen/clipboard, never one handed to it by the server, so a
/// malicious server can't substitute its own key and intercept the seed.
class LinkPayload {
  const LinkPayload({
    required this.sessionId,
    required this.ephemeralPublicKey,
    required this.linkSecret,
  });

  static const prefix = 'agora-link';
  static const version = '1';

  /// Doubles as the mailbox document id (base64url is a legal Firestore id).
  final String sessionId;
  final List<int> ephemeralPublicKey;
  final List<int> linkSecret;

  /// Fresh session: random id, ephemeral key and secret.
  static LinkPayload generate(List<int> ephemeralPublicKey) => LinkPayload(
        sessionId: _b64(PassphraseEnvelope.randomBytes(16)),
        ephemeralPublicKey: ephemeralPublicKey,
        linkSecret: PassphraseEnvelope.randomBytes(32),
      );

  /// `agora-link:1:<sessionId>:<epk>:<linkSecret>:<check>` — the trailing
  /// checksum catches a truncated paste before it costs a round trip.
  String encode() {
    final body = '$prefix:$version:$sessionId:'
        '${_b64(ephemeralPublicKey)}:${_b64(linkSecret)}';
    return '$body:${_checksum(body)}';
  }

  static LinkPayload decode(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length != 6) throw const LinkPayloadException(LinkPayloadError.truncated);
    if (parts[0] != prefix) {
      throw const LinkPayloadException(LinkPayloadError.badPrefix);
    }
    if (parts[1] != version) {
      throw const LinkPayloadException(LinkPayloadError.badVersion);
    }
    final body = parts.take(5).join(':');
    if (_checksum(body) != parts[5]) {
      throw const LinkPayloadException(LinkPayloadError.badChecksum);
    }
    final List<int> epk, secret;
    try {
      epk = base64Url.decode(_pad(parts[3]));
      secret = base64Url.decode(_pad(parts[4]));
    } on FormatException {
      throw const LinkPayloadException(LinkPayloadError.truncated);
    }
    if (epk.length != 32 || secret.length != 32) {
      throw const LinkPayloadException(LinkPayloadError.truncated);
    }
    return LinkPayload(
      sessionId: parts[2],
      ephemeralPublicKey: epk,
      linkSecret: secret,
    );
  }

  static String _checksum(String body) {
    // Truncated SHA-256 — an integrity hint for humans, not a MAC.
    final digest = const DartSha256().hashSync(utf8.encode(body)).bytes;
    return _b64(digest.take(4).toList());
  }

  static String _b64(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static String _pad(String s) => s.padRight((s.length + 3) & ~3, '=');
}

/// Seals the identity seed from one device to another.
///
/// Deliberately a sibling of [SealedBox] rather than a parameterisation of
/// it: touching that KDF would invalidate every `wrappedCck` already stored,
/// and the two constructions must stay domain-separated so a link box can
/// never be replayed as a congregation-key box.
abstract final class DeviceLinkBox {
  static const _domain = 'agora.link.v1';

  static final _x25519 = X25519();
  static final _aes = AesGcm.with256bits();

  /// Binds the derived key to both ephemeral keys, the out-of-band secret,
  /// the account and the session — so a box is useless anywhere else.
  static Future<SecretKey> _key({
    required SecretKey shared,
    required List<int> senderEpk,
    required List<int> recipientEpk,
    required List<int> linkSecret,
    required String uid,
    required String sessionId,
  }) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final key = await hkdf.deriveKey(
      secretKey: shared,
      info: [
        ...utf8.encode(_domain),
        ...senderEpk,
        ...recipientEpk,
        ...linkSecret,
        ...utf8.encode(uid),
        ...utf8.encode(sessionId),
      ],
    );
    return SecretKey(await key.extractBytes());
  }

  static List<int> _aad(String uid, String sessionId) =>
      utf8.encode('$uid/$sessionId');

  /// EXISTING device: seal [seed] to the ephemeral key from the scanned or
  /// pasted [payload]. Never pass a key read from the server here.
  static Future<Map<String, String>> seal({
    required List<int> seed,
    required LinkPayload payload,
    required String uid,
  }) async {
    final ephemeral = await _x25519.newKeyPair();
    final senderEpk = (await ephemeral.extractPublicKey()).bytes;
    final shared = await _x25519.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: SimplePublicKey(payload.ephemeralPublicKey,
          type: KeyPairType.x25519),
    );
    final nonce = PassphraseEnvelope.randomBytes(12);
    final box = await _aes.encrypt(
      seed,
      secretKey: await _key(
        shared: shared,
        senderEpk: senderEpk,
        recipientEpk: payload.ephemeralPublicKey,
        linkSecret: payload.linkSecret,
        uid: uid,
        sessionId: payload.sessionId,
      ),
      nonce: nonce,
      aad: _aad(uid, payload.sessionId),
    );
    return {
      'v': '1',
      'epk': LinkPayload._b64(senderEpk),
      'nonce': LinkPayload._b64(nonce),
      'ct': LinkPayload._b64(box.cipherText),
      'mac': LinkPayload._b64(box.mac.bytes),
    };
  }

  /// NEW device: open the mailbox response with the ephemeral private key
  /// whose public half went out in the payload.
  ///
  /// Opening successfully does NOT prove the seed is the right one — the
  /// caller MUST still check it derives the account's published public key
  /// (see LinkService), or a forged response would silently break sync.
  static Future<List<int>> open({
    required Map<String, dynamic> response,
    required List<int> ephemeralSeed,
    required LinkPayload payload,
    required String uid,
  }) async {
    final List<int> senderEpk, nonce, ct, mac;
    try {
      senderEpk = base64Url.decode(LinkPayload._pad(response['epk'] as String));
      nonce = base64Url.decode(LinkPayload._pad(response['nonce'] as String));
      ct = base64Url.decode(LinkPayload._pad(response['ct'] as String));
      mac = base64Url.decode(LinkPayload._pad(response['mac'] as String));
    } catch (e) {
      throw DeviceLinkException('Malformed link response.', e);
    }
    final keyPair = await _x25519.newKeyPairFromSeed(ephemeralSeed);
    final shared = await _x25519.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: SimplePublicKey(senderEpk, type: KeyPairType.x25519),
    );
    try {
      return await _aes.decrypt(
        SecretBox(ct, nonce: nonce, mac: Mac(mac)),
        secretKey: await _key(
          shared: shared,
          senderEpk: senderEpk,
          recipientEpk: payload.ephemeralPublicKey,
          linkSecret: payload.linkSecret,
          uid: uid,
          sessionId: payload.sessionId,
        ),
        aad: _aad(uid, payload.sessionId),
      );
    } on SecretBoxAuthenticationError catch (e) {
      throw DeviceLinkException('Link response failed authentication.', e);
    }
  }

  /// Ephemeral keypair for the NEW device: returns its seed (kept in memory
  /// only) and the public half that travels in the payload.
  static Future<(List<int> seed, List<int> publicKey)> newEphemeral() async {
    final seed = PassphraseEnvelope.randomBytes(32);
    final pub = (await (await _x25519.newKeyPairFromSeed(seed))
            .extractPublicKey())
        .bytes;
    return (seed, pub);
  }
}
