import 'dart:async';

import 'device_link.dart';
import 'key_docs_gateway.dart';
import 'sealed_box.dart';
import 'user_key_service.dart';

/// The transferred seed opened fine but is NOT this account's identity.
/// Someone answered the mailbox with a key of their own: refuse it loudly
/// rather than adopting a seed that would silently break every decrypt.
class LinkIdentityMismatch implements Exception {
  const LinkIdentityMismatch();

  @override
  String toString() => 'The linked device returned a different identity key.';
}

/// A link session in progress on the NEW device: what to show, and the
/// ephemeral private half kept in memory only.
class LinkSession {
  LinkSession({required this.payload, required this.ephemeralSeed});

  final LinkPayload payload;
  final List<int> ephemeralSeed;

  /// The string to show as QR / let the user copy.
  String get code => payload.encode();
}

/// Moves the identity seed from a device that has it to one that doesn't,
/// without the server ever being able to read it.
///
/// The security rests on two independent factors: writing the mailbox needs
/// the ACCOUNT (rules), and opening the box needs the PAYLOAD, which travels
/// out of band (QR / copy-paste) and never through Firestore. The operator
/// has neither.
class LinkService {
  LinkService(this._docs, this._userKeys, {required this.uid});

  final KeyDocsGateway _docs;
  final UserKeyService _userKeys;
  final String uid;

  /// Bounded by the rules; keep in sync with them.
  static const ttl = Duration(minutes: 5);
  static const _poll = Duration(seconds: 2);

  /// NEW device: open a mailbox and produce the payload to display.
  Future<LinkSession> start() async {
    final (ephemeralSeed, publicKey) = await DeviceLinkBox.newEphemeral();
    final payload = LinkPayload.generate(publicKey);
    await _docs.createLinkMailbox(uid, payload.sessionId, ttl);
    return LinkSession(payload: payload, ephemeralSeed: ephemeralSeed);
  }

  /// NEW device: wait for the other device to answer, verify and adopt the
  /// seed. Returns false if the session expired without an answer.
  ///
  /// Throws [LinkIdentityMismatch] when the seed isn't the account's, and
  /// [DeviceLinkException] when the box doesn't open.
  Future<bool> awaitCompletion(LinkSession session) async {
    final deadline = DateTime.now().add(ttl);
    while (DateTime.now().isBefore(deadline)) {
      final response =
          await _docs.readLinkResponse(uid, session.payload.sessionId);
      if (response != null) {
        return _adopt(session, response);
      }
      await Future<void>.delayed(_poll);
    }
    await cancel(session);
    return false;
  }

  Future<bool> _adopt(
      LinkSession session, Map<String, dynamic> response) async {
    final seed = await DeviceLinkBox.open(
      response: response,
      ephemeralSeed: session.ephemeralSeed,
      payload: session.payload,
      uid: uid,
    );
    // Opening proves the sender had the payload — NOT that the seed is the
    // real identity. Without this check a forged answer would be adopted and
    // every congregation key would silently fail to open.
    final derived = await SealedBox.publicKeyOf(seed);
    final published = await _userKeys.publishedPublicKey();
    if (published == null || !_sameBytes(derived, published)) {
      await cancel(session);
      throw const LinkIdentityMismatch();
    }
    await _userKeys.adopt(seed);
    await cancel(session);
    return true;
  }

  /// Best-effort mailbox cleanup (a leftover is harmless — it only holds a
  /// box sealed to an ephemeral key that no longer exists — and Firestore's
  /// TTL sweeps it anyway).
  Future<void> cancel(LinkSession session) async {
    try {
      await _docs.deleteLinkMailbox(uid, session.payload.sessionId);
    } catch (_) {}
  }

  /// EXISTING device: read the scanned/pasted code and answer the mailbox.
  ///
  /// Throws [LinkPayloadException] on a bad code and [StateError] when this
  /// device holds no seed to share.
  Future<void> approve(String code) async {
    final payload = LinkPayload.decode(code);
    final seed = await _userKeys.seed();
    if (seed == null) {
      throw StateError('This device has no sync identity to share.');
    }
    await _docs.writeLinkResponse(
      uid,
      payload.sessionId,
      // The recipient key comes from the CODE, never from Firestore: that is
      // what stops a malicious server from substituting its own.
      await DeviceLinkBox.seal(seed: seed, payload: payload, uid: uid),
    );
  }

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
