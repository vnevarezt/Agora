/// The Firestore documents the key services touch, behind an interface so
/// unit tests run on an in-memory fake (cloud_firestore needs platform
/// channels). Timestamps (`createdAt`, `keyUpdatedAt`) are the GATEWAY's
/// job — services pass pure content maps.
abstract interface class KeyDocsGateway {
  /// `users/{uid}` content, or null when the user never set up sync keys.
  Future<Map<String, dynamic>?> readUserDoc(String uid);

  /// Creates or replaces `users/{uid}` with [data] + server timestamps.
  Future<void> writeUserDoc(String uid, Map<String, dynamic> data);

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
