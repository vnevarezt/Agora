/// The Firestore documents the key services touch, behind an interface so
/// unit tests run on an in-memory fake (cloud_firestore needs platform
/// channels). Timestamps (`createdAt`, `keyUpdatedAt`) are the GATEWAY's
/// job — services pass pure content maps.
abstract interface class KeyDocsGateway {
  /// `users/{uid}` content, or null when the user never set up sync keys.
  Future<Map<String, dynamic>?> readUserDoc(String uid);

  /// Publishes the identity doc for the first time (public key only; the
  /// private seed never leaves the device). Stamps both timestamps.
  Future<void> createUserDoc(String uid, {required String pubKey});

  /// Touches `keyUpdatedAt` and drops the legacy passphrase envelope from a
  /// pre-4c doc. Must NOT re-stamp `createdAt` (and the rules reject a doc
  /// still carrying `wrappedPrivKey`).
  Future<void> dropLegacyEnvelope(String uid);

  /// Creates the empty device-linking mailbox the new device polls.
  /// [ttl] is bounded by the rules (max 10 minutes).
  Future<void> createLinkMailbox(String uid, String sessionId, Duration ttl);

  /// The sealed response an existing device left, or null while it hasn't
  /// answered yet. Null also when the mailbox is gone.
  Future<Map<String, dynamic>?> readLinkResponse(String uid, String sessionId);

  /// Existing device: drop the sealed seed into the mailbox (write-once).
  Future<void> writeLinkResponse(
      String uid, String sessionId, Map<String, String> response);

  Future<void> deleteLinkMailbox(String uid, String sessionId);

  /// `congregations/{cid}/members/{uid}`, or null when not a member.
  Future<Map<String, dynamic>?> readMemberDoc(String cid, String uid);

  /// Clear `keyVersion` of `congregations/{cid}`, or null when the
  /// congregation has no cloud space yet.
  Future<int?> readCongregationKeyVersion(String cid);

  /// Founder bootstrap, ONE batch: `congregations/{cid}` ({createdBy: uid,
  /// keyVersion: 1}) + the founder's member doc. Rules only accept the two
  /// together (getAfter cross-check).
  Future<void> createCongregationSpace({
    required String cid,
    required String uid,
    required Map<String, dynamic> memberData,
  });
}
