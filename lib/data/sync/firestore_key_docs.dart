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

  @override
  Future<Map<String, dynamic>?> readUserDoc(String uid) async {
    final snap = await _user(uid).get(const GetOptions(source: Source.server));
    return snap.data();
  }

  @override
  Future<void> createUserDoc(String uid, {required String pubKey}) =>
      _user(uid).set({
        'pubKey': pubKey,
        'keyUpdatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> dropLegacyEnvelope(String uid) => _user(uid).update({
        'wrappedPrivKey': FieldValue.delete(),
        'keyUpdatedAt': FieldValue.serverTimestamp(),
      });

  DocumentReference<Map<String, dynamic>> _link(String uid, String sessionId) =>
      _user(uid).collection('links').doc(sessionId);

  @override
  Future<void> createLinkMailbox(String uid, String sessionId, Duration ttl) =>
      _link(uid, sessionId).set({
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().toUtc().add(ttl)),
      });

  @override
  Future<Map<String, dynamic>?> readLinkResponse(
      String uid, String sessionId) async {
    final data = await _readOrNull(() => _link(uid, sessionId).get(_serverSource));
    return (data?['response'] as Map?)?.cast<String, dynamic>();
  }

  @override
  Future<void> writeLinkResponse(
          String uid, String sessionId, Map<String, String> response) =>
      _link(uid, sessionId).update({'response': response});

  @override
  Future<void> deleteLinkMailbox(String uid, String sessionId) =>
      _link(uid, sessionId).delete();

  @override
  Future<Map<String, dynamic>?> readMemberDoc(String cid, String uid) async {
    // permission-denied here means "not a cloud member of this congregation"
    // (a local-only congregation, or one this user was never invited to /
    // was revoked from). The rules deny reading a member doc you have no
    // claim to; the caller must read that as "no keyring → not syncable →
    // stays queued", NOT as a hard failure.
    return _readOrNull(() => _member(cid, uid).get(_serverSource));
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
}
