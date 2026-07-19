/// The Firestore documents the key services touch, behind an interface so
/// unit tests run on an in-memory fake (cloud_firestore needs platform
/// channels). Timestamps (`createdAt`, `keyUpdatedAt`) are the GATEWAY's
/// job — services pass pure content maps.
abstract interface class KeyDocsGateway {
  /// `users/{uid}` content, or null when the user never set up sync keys.
  Future<Map<String, dynamic>?> readUserDoc(String uid);

  /// Publishes the identity doc for the first time. [privKey] is escrowed
  /// here on purpose: it is what lets signing in restore everything with no
  /// code to remember (see UserKeyService for the cost of that choice).
  /// Stamps both timestamps.
  Future<void> createUserDoc(String uid,
      {required String pubKey, required String privKey});

  /// Touches `keyUpdatedAt` and drops the legacy passphrase envelope from a
  /// pre-4c doc. Must NOT re-stamp `createdAt`.
  Future<void> dropLegacyEnvelope(String uid);

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
