import 'package:jw_program/data/sync/key_docs_gateway.dart';

/// In-memory [KeyDocsGateway]: the docs the key services would keep in
/// Firestore, minus the network and the rules.
class FakeKeyDocs implements KeyDocsGateway {
  final Map<String, Map<String, dynamic>> users = {};

  /// cid → uid → member doc.
  final Map<String, Map<String, Map<String, dynamic>>> members = {};

  /// cid → congregation meta doc.
  final Map<String, Map<String, dynamic>> congregations = {};

  /// uid → sessionId → mailbox doc.
  final Map<String, Map<String, Map<String, dynamic>>> links = {};

  @override
  Future<Map<String, dynamic>?> readUserDoc(String uid) async => users[uid];

  @override
  Future<void> createUserDoc(String uid, {required String pubKey}) async {
    users[uid] = {
      'pubKey': pubKey,
      'createdAt': DateTime.now().toUtc(),
      'keyUpdatedAt': DateTime.now().toUtc(),
    };
  }

  @override
  Future<void> dropLegacyEnvelope(String uid) async {
    users[uid]?.remove('wrappedPrivKey');
  }

  @override
  Future<void> createLinkMailbox(
      String uid, String sessionId, Duration ttl) async {
    (links[uid] ??= {})[sessionId] = {
      'createdAt': DateTime.now().toUtc(),
      'expiresAt': DateTime.now().toUtc().add(ttl),
    };
  }

  @override
  Future<Map<String, dynamic>?> readLinkResponse(
          String uid, String sessionId) async =>
      (links[uid]?[sessionId]?['response'] as Map?)?.cast<String, dynamic>();

  @override
  Future<void> writeLinkResponse(
      String uid, String sessionId, Map<String, String> response) async {
    final mailbox = links[uid]?[sessionId];
    if (mailbox == null) throw StateError('no mailbox $uid/$sessionId');
    if (mailbox.containsKey('response')) {
      throw StateError('response already written'); // rules: write-once
    }
    mailbox['response'] = response;
  }

  @override
  Future<void> deleteLinkMailbox(String uid, String sessionId) async {
    links[uid]?.remove(sessionId);
  }

  @override
  Future<Map<String, dynamic>?> readMemberDoc(String cid, String uid) async =>
      members[cid]?[uid];

  @override
  Future<int?> readCongregationKeyVersion(String cid) async =>
      congregations[cid]?['keyVersion'] as int?;

  @override
  Future<void> createCongregationSpace({
    required String cid,
    required String uid,
    required Map<String, dynamic> memberData,
  }) async {
    congregations[cid] = {'createdBy': uid, 'keyVersion': 1};
    (members[cid] ??= {})[uid] = Map.of(memberData);
  }
}
