import 'package:cloud_firestore/cloud_firestore.dart';

import 'key_docs_gateway.dart';

/// [KeyDocsGateway] backed by cloud_firestore. Server timestamps are set
/// here so the services stay platform-free (and unit-testable via
/// FakeKeyDocs). Reads use [Source.server] for the same reason the
/// transport does: latency-compensated cache can hand back a doc whose
/// serverTimestamp fields are still null.
class FirestoreKeyDocs implements KeyDocsGateway {
  FirestoreKeyDocs(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _congregation(String cid) =>
      _db.collection('congregations').doc(cid);

  DocumentReference<Map<String, dynamic>> _member(String cid, String uid) =>
      _congregation(cid).collection('members').doc(uid);

  DocumentReference<Map<String, dynamic>> _invite(String cid, String id) =>
      _congregation(cid).collection('invites').doc(id);

  /// Firestore `Timestamp`s become `DateTime`s here so models and services
  /// stay free of cloud_firestore (the gateway owns timestamps, see the
  /// interface doc).
  static Map<String, dynamic> _normalize(Map<String, dynamic> data) => {
        for (final MapEntry(:key, :value) in data.entries)
          key: value is Timestamp ? value.toDate().toUtc() : value,
      };

  @override
  Future<Map<String, dynamic>?> readUserDoc(String uid) async {
    final snap = await _user(uid).get(const GetOptions(source: Source.server));
    return snap.data();
  }

  @override
  Future<void> createUserDoc(String uid,
          {required String pubKey, required String privKey}) =>
      _user(uid).set({
        'pubKey': pubKey,
        'privKey': privKey,
        'keyUpdatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> dropLegacyEnvelope(String uid) => _user(uid).update({
        'wrappedPrivKey': FieldValue.delete(),
        'keyUpdatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<Map<String, dynamic>?> readMemberDoc(String cid, String uid) async {
    // permission-denied here means "not a cloud member of this congregation"
    // (a local-only congregation, or one this user was never invited to /
    // was revoked from). The rules deny reading a member doc you have no
    // claim to; the caller must read that as "no keyring → not syncable →
    // stays queued", NOT as a hard failure.
    final data = await _readOrNull(() => _member(cid, uid).get(_serverSource));
    return data == null ? null : _normalize(data);
  }

  @override
  Future<int?> readCongregationKeyVersion(String cid) async {
    final data =
        await _readOrNull(() => _congregation(cid).get(_serverSource));
    return data?['keyVersion'] as int?;
  }

  static const _serverSource = GetOptions(source: Source.server);

  /// Runs a doc get, returning its data or null — including when the rules
  /// deny the read (treated as "not accessible" rather than an error).
  Future<Map<String, dynamic>?> _readOrNull(
    Future<DocumentSnapshot<Map<String, dynamic>>> Function() get,
  ) async {
    try {
      return (await get()).data();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  @override
  Future<void> createCongregationSpace({
    required String cid,
    required String uid,
    required Map<String, dynamic> memberData,
  }) {
    // Rules only accept the founder member doc when the SAME batch also
    // creates the congregation (getAfter cross-check).
    final batch = _db.batch();
    batch.set(_congregation(cid), {
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'keyVersion': 1,
    });
    batch.set(_member(cid, uid), {
      ...memberData,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  // ---- members --------------------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> listMembers(String cid) async {
    try {
      final snap =
          await _congregation(cid).collection('members').get(_serverSource);
      return [for (final d in snap.docs) _normalize(d.data())];
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return const [];
      rethrow;
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMembers(String cid) =>
      _congregation(cid)
          .collection('members')
          .snapshots()
          .map((s) => [for (final d in s.docs) _normalize(d.data())]);

  @override
  Future<void> updateMemberCapabilities(
          String cid, String uid, Map<String, Object> capabilities) =>
      _member(cid, uid).update({'capabilities': capabilities});

  @override
  Future<void> appendWrappedCcks(
          String cid, String uid, Map<int, Map<String, String>> boxes) =>
      _member(cid, uid).set(_wrappedPatch(boxes), SetOptions(merge: true));

  /// Appends key versions without rewriting the existing ones.
  ///
  /// A merged `set` of a NESTED map deep-merges its entries, which is exactly
  /// the append the rules demand (`wrappedCcks.keys().hasAll(old)`). We avoid
  /// `update` with a dotted `'wrappedCcks.2'` on purpose: the Dart SDK's field
  /// path parser is stricter than the JS one about numeric segments, and the
  /// `FieldPath` alternative doesn't type-check against `WriteBatch.update<T>`
  /// on a `DocumentReference<Map<String, dynamic>>`.
  ///
  /// Merging into a missing doc would CREATE it — with only `wrappedCcks`,
  /// which the create rule rejects (it demands uid/pubKey/capabilities/…).
  /// So a rotation racing a member's departure fails closed.
  static Map<String, dynamic> _wrappedPatch(
          Map<int, Map<String, String>> boxes) =>
      {
        'wrappedCcks': {
          for (final MapEntry(key: version, value: box) in boxes.entries)
            '$version': box,
        },
      };

  // ---- invites --------------------------------------------------------------

  @override
  Future<void> createInvite(
          String cid, String tokenId, Map<String, dynamic> data) =>
      _invite(cid, tokenId).set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<Map<String, dynamic>?> readInvite(String cid, String tokenId) async {
    final data = await _readOrNull(() => _invite(cid, tokenId).get(_serverSource));
    return data == null ? null : _normalize(data);
  }

  @override
  Future<Map<String, Map<String, dynamic>>> listInvites(String cid) async {
    try {
      final snap =
          await _congregation(cid).collection('invites').get(_serverSource);
      return {for (final d in snap.docs) d.id: _normalize(d.data())};
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return const {};
      rethrow;
    }
  }

  @override
  Stream<Map<String, Map<String, dynamic>>> watchInvites(String cid) =>
      _congregation(cid)
          .collection('invites')
          .snapshots()
          .map((s) => {for (final d in s.docs) d.id: _normalize(d.data())});

  @override
  Future<void> deleteInvite(String cid, String tokenId) =>
      _invite(cid, tokenId).delete();

  @override
  Future<void> redeemInvite({
    required String cid,
    required String uid,
    required String tokenId,
    required Map<String, dynamic> memberData,
  }) {
    // The rules prove single-use by comparing exists() (pre-batch) with
    // existsAfter() (post-batch) on the invite: the create and the delete
    // MUST ride together or neither is allowed.
    final batch = _db.batch();
    batch.set(_member(cid, uid), {
      ...memberData,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.delete(_invite(cid, tokenId));
    return batch.commit();
  }

  // ---- rotation -------------------------------------------------------------

  /// Firestore hard-caps a batch at 500 writes; leaving headroom keeps the
  /// congregation doc + deletes safely inside it.
  static const _maxBatchWrites = 450;

  @override
  Future<void> rotateKey({
    required String cid,
    required int newKeyVersion,
    required Map<String, Map<String, String>> wrappedForMember,
    Iterable<String> removeMemberUids = const [],
    Iterable<String> deleteInviteIds = const [],
  }) {
    final removals = removeMemberUids.toList();
    final invites = deleteInviteIds.toList();
    final writes =
        1 + wrappedForMember.length + removals.length + invites.length;
    if (writes > _maxBatchWrites) {
      // Splitting would break atomicity: a half-rotated congregation leaves
      // members who can't read the new writes and a revoked member who still
      // can. Better to refuse than to corrupt.
      throw StateError(
          'Rotation needs $writes writes, over the $_maxBatchWrites batch '
          'limit. Remove members in smaller groups.');
    }

    final batch = _db.batch();
    for (final MapEntry(key: uid, value: box) in wrappedForMember.entries) {
      batch.set(
        _member(cid, uid),
        _wrappedPatch({newKeyVersion: box}),
        SetOptions(merge: true),
      );
    }
    for (final uid in removals) {
      batch.delete(_member(cid, uid));
    }
    // Pending invites carry an IMMUTABLE wrappedKeyring frozen at the old
    // version (`update: if false`): left alive, their redeemer would join
    // unable to read anything written after this rotation.
    for (final id in invites) {
      batch.delete(_invite(cid, id));
    }
    batch.update(_congregation(cid), {'keyVersion': newKeyVersion});
    return batch.commit();
  }
}
