import 'package:jw_program/data/sync/key_docs_gateway.dart';

/// In-memory [KeyDocsGateway]: the docs the key services would keep in
/// Firestore, minus the network and the rules.
class FakeKeyDocs implements KeyDocsGateway {
  final Map<String, Map<String, dynamic>> users = {};

  /// cid → uid → member doc.
  final Map<String, Map<String, Map<String, dynamic>>> members = {};

  /// cid → congregation meta doc.
  final Map<String, Map<String, dynamic>> congregations = {};

  @override
  Future<Map<String, dynamic>?> readUserDoc(String uid) async => users[uid];

  @override
  Future<void> createUserDoc(String uid,
      {required String pubKey, required String privKey}) async {
    users[uid] = {
      'pubKey': pubKey,
      'privKey': privKey,
      'createdAt': DateTime.now().toUtc(),
      'keyUpdatedAt': DateTime.now().toUtc(),
    };
  }

  @override
  Future<void> dropLegacyEnvelope(String uid) async {
    users[uid]?.remove('wrappedPrivKey');
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
