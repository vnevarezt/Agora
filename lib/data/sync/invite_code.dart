import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../crypto/passphrase_envelope.dart' show PassphraseEnvelope;
import 'content_crypto.dart';

/// The code could not be read: wrong shape, a mistyped/truncated character
/// (the check digits catch it) or a version this build doesn't know.
class InviteCodeException implements Exception {
  const InviteCodeException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A share code: `agora-inv:1:<cid>:<tokenId>:<secret>:<check>`.
///
/// [tokenId] IS the invite document's id — the rules grant `get` on an invite
/// to anyone signed in, so the unguessable id is the read credential. [secret]
/// never reaches the server: it unwraps the keyring the admin sealed into the
/// invite, which is what makes redemption end-to-end (see [InviteKeyringBox]).
///
/// ~124 characters: meant to be copied/shared, not typed. [check] is a
/// truncated SHA-256 over the other fields — transcription integrity only,
/// NOT a MAC (anyone holding the code can recompute it); the real
/// authentication is the AEAD tag on the wrapped keyring.
class InviteCode {
  const InviteCode({
    required this.congregationId,
    required this.tokenId,
    required this.secret,
  });

  static const _prefix = 'agora-inv';
  static const _version = '1';
  static const _checkBytes = 6;

  final String congregationId;

  /// 16 random bytes, base64url — also the `invites/{tokenId}` document id.
  final String tokenId;

  /// 32 random bytes. The only part the server never sees.
  final List<int> secret;

  /// Fresh token + secret for [congregationId].
  factory InviteCode.mint(String congregationId) => InviteCode(
        congregationId: congregationId,
        tokenId: _b64(PassphraseEnvelope.randomBytes(16)),
        secret: PassphraseEnvelope.randomBytes(32),
      );

  String encode() {
    final body = _body(congregationId, tokenId, _b64(secret));
    return '$body:${_check(body)}';
  }

  /// Parses a shared code, tolerating surrounding whitespace and case in the
  /// prefix (chat clients love to capitalize). Throws [InviteCodeException]
  /// on anything malformed.
  factory InviteCode.parse(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length != 6) {
      throw const InviteCodeException('Not an invite code.');
    }
    final [prefix, version, cid, tokenId, secret, check] = parts;
    if (prefix.toLowerCase() != _prefix) {
      throw const InviteCodeException('Not an invite code.');
    }
    if (version != _version) {
      throw InviteCodeException('Unsupported invite code version $version.');
    }
    final body = _body(cid, tokenId, secret);
    if (_check(body) != check) {
      throw const InviteCodeException('The invite code is incomplete or was '
          'copied wrong.');
    }
    final List<int> bytes;
    try {
      bytes = _unb64(secret);
    } on FormatException {
      throw const InviteCodeException('The invite code is malformed.');
    }
    if (bytes.length != 32 || cid.isEmpty || tokenId.isEmpty) {
      throw const InviteCodeException('The invite code is malformed.');
    }
    return InviteCode(
        congregationId: cid, tokenId: tokenId, secret: bytes);
  }

  static String _body(String cid, String tokenId, String secret) =>
      '$_prefix:$_version:$cid:$tokenId:$secret';

  static final _sha256 = Sha256().toSync();

  static String _check(String body) => _b64(
      _sha256.hashSync(utf8.encode(body)).bytes.take(_checkBytes).toList());

  static String _b64(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static List<int> _unb64(String s) =>
      base64Url.decode(s.padRight((s.length + 3) & ~3, '='));
}

/// The invite's `wrappedKeyring`: the FULL congregation keyring (every
/// version, so the redeemer can read history) under a key derived from the
/// code's secret.
///
/// Both the HKDF info and the AEAD's AAD bind the box to `cid` + `tokenId`,
/// exactly as [SealedBox] binds to its recipient: a `wrappedKeyring` copied
/// into another congregation's invite — or into another token in the same
/// congregation — fails authentication instead of decrypting.
abstract final class InviteKeyringBox {
  static const _info = 'agora.invite.v1';

  static final _aes = AesGcm.with256bits();

  static Future<SecretKey> _derive(InviteCode code) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    return hkdf.deriveKey(
      secretKey: SecretKey(code.secret),
      info: utf8.encode('$_info:${code.congregationId}:${code.tokenId}'),
    );
  }

  static List<int> _aad(InviteCode code) =>
      utf8.encode('${code.congregationId}/${code.tokenId}');

  /// Box map `{v, nonce, ct, mac}` (base64 fields), Firestore-ready.
  static Future<Map<String, String>> seal(
    CongregationKeyring keyring,
    InviteCode code,
  ) async {
    final clear = utf8.encode(jsonEncode(keyring.keys
        .map((version, key) => MapEntry('$version', base64Encode(key)))));
    final nonce = PassphraseEnvelope.randomBytes(12);
    final box = await _aes.encrypt(
      clear,
      secretKey: await _derive(code),
      nonce: nonce,
      aad: _aad(code),
    );
    return {
      'v': '1',
      'nonce': base64Encode(nonce),
      'ct': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    };
  }

  /// Opens a [seal]ed keyring. Throws [InviteCodeException] when the secret
  /// is wrong, the box was tampered with, or it belongs to another
  /// congregation/token.
  static Future<CongregationKeyring> open(
    Map<String, dynamic> box,
    InviteCode code,
  ) async {
    final List<int> nonce, ct, mac;
    try {
      nonce = base64Decode(box['nonce'] as String);
      ct = base64Decode(box['ct'] as String);
      mac = base64Decode(box['mac'] as String);
    } catch (e) {
      throw const InviteCodeException('The invitation is malformed.');
    }
    final List<int> clear;
    try {
      clear = await _aes.decrypt(
        SecretBox(ct, nonce: nonce, mac: Mac(mac)),
        secretKey: await _derive(code),
        aad: _aad(code),
      );
    } on SecretBoxAuthenticationError {
      throw const InviteCodeException(
          'This invite code does not open this invitation.');
    }
    try {
      final map = (jsonDecode(utf8.decode(clear)) as Map<String, dynamic>).map(
          (version, b64) =>
              MapEntry(int.parse(version), base64Decode(b64 as String)));
      if (map.isEmpty) throw const FormatException('empty keyring');
      return CongregationKeyring(map);
    } catch (e) {
      throw const InviteCodeException('The invitation carries no usable keys.');
    }
  }
}
