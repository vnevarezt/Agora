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

  // ---- members (admin screens) ---------------------------------------------

  /// Every member doc of [cid]. Admin/member-only per the rules; returns an
  /// empty list when the read is denied (same contract as [readMemberDoc]).
  Future<List<Map<String, dynamic>>> listMembers(String cid);

  /// Live member list — the admin screen's stream. Same denial contract.
  Stream<List<Map<String, dynamic>>> watchMembers(String cid);

  /// Replaces `capabilities` on a member doc (admin only). Never touches the
  /// identity fields the rules freeze.
  Future<void> updateMemberCapabilities(
      String cid, String uid, Map<String, Object> capabilities);

  /// Adds key versions to a member's `wrappedCcks` WITHOUT rewriting the
  /// existing ones (the rules require `hasAll` of the old keys) — the
  /// reconciliation path for a member who missed a rotation.
  Future<void> appendWrappedCcks(
      String cid, String uid, Map<int, Map<String, String>> boxes);

  // ---- invites -------------------------------------------------------------

  /// Creates `invites/{tokenId}`. Stamps `createdAt`; [data] carries
  /// capabilities, wrappedKeyring, createdBy and expiresAt.
  Future<void> createInvite(
      String cid, String tokenId, Map<String, dynamic> data);

  /// One invite by id — the token in the shared code IS the read credential,
  /// so this works for a not-yet-member. Null when missing or denied.
  Future<Map<String, dynamic>?> readInvite(String cid, String tokenId);

  /// Pending invites of [cid], keyed by tokenId (admin only, empty on deny).
  Future<Map<String, Map<String, dynamic>>> listInvites(String cid);

  /// Live pending invites — the admin screen's stream.
  Stream<Map<String, Map<String, dynamic>>> watchInvites(String cid);

  /// Cancels a pending invite (admin), or drops one dangling after a failed
  /// redemption.
  Future<void> deleteInvite(String cid, String tokenId);

  /// Redemption, ONE batch: create `members/{uid}` + DELETE the invite. The
  /// rules prove single-use from exists()/existsAfter() of that same batch,
  /// so these two can never be split.
  Future<void> redeemInvite({
    required String cid,
    required String uid,
    required String tokenId,
    required Map<String, dynamic> memberData,
  });

  // ---- rotation ------------------------------------------------------------

  /// Revoke + rotate, ONE batch: append [wrappedForMember] (uid → sealed box)
  /// as version [newKeyVersion] on each surviving member, delete the member
  /// docs in [removeMemberUids] and the invites in [deleteInviteIds], and
  /// bump the congregation's `keyVersion`.
  ///
  /// Atomic on purpose: `isAdmin` reads the CALLER's doc in its PRE-batch
  /// state, which is what lets a departing admin revoke themselves and rotate
  /// in the same commit. Splitting it would both break that and leave the
  /// congregation half-rotated.
  Future<void> rotateKey({
    required String cid,
    required int newKeyVersion,
    required Map<String, Map<String, String>> wrappedForMember,
    Iterable<String> removeMemberUids = const [],
    Iterable<String> deleteInviteIds = const [],
  });
}
