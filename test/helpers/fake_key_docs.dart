import 'dart:async';

import 'package:jw_program/data/sync/key_docs_gateway.dart';

/// In-memory [KeyDocsGateway]: the docs the key services would keep in
/// Firestore, minus the network and the rules.
class FakeKeyDocs implements KeyDocsGateway {
  final Map<String, Map<String, dynamic>> users = {};

  /// cid → uid → member doc.
  final Map<String, Map<String, Map<String, dynamic>>> members = {};

  /// cid → congregation meta doc.
  final Map<String, Map<String, dynamic>> congregations = {};

  /// cid → tokenId → invite doc.
  final Map<String, Map<String, Map<String, dynamic>>> invites = {};

  /// Every [rotateKey] call, in order — lets tests assert the batch shape
  /// (which is where the rules' atomicity guarantees live).
  final List<({int version, Set<String> sealedFor, Set<String> removed,
      Set<String> invitesDeleted})> rotations = [];

  final _memberStreams = <String, StreamController<List<Map<String, dynamic>>>>{};
  final _inviteStreams =
      <String, StreamController<Map<String, Map<String, dynamic>>>>{};

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
    _emitMembers(cid);
  }

  // ---- members --------------------------------------------------------------

  /// Runs INSIDE [listMembers], after the snapshot is taken but before it is
  /// returned — the exact window a concurrent write has to land in to be
  /// missed by the caller's next batch.
  Future<void> Function()? onListMembers;

  @override
  Future<List<Map<String, dynamic>>> listMembers(String cid) async {
    final snapshot = [
      for (final m in (members[cid] ?? const {}).values) Map.of(m),
    ];
    await onListMembers?.call();
    return snapshot;
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMembers(String cid) {
    final c = _memberStreams.putIfAbsent(
        cid, () => StreamController<List<Map<String, dynamic>>>.broadcast());
    scheduleMicrotask(() => _emitMembers(cid));
    return c.stream;
  }

  @override
  Future<void> updateMemberCapabilities(
      String cid, String uid, Map<String, Object> capabilities) async {
    final doc = members[cid]?[uid];
    if (doc == null) throw StateError('no member $uid in $cid');
    doc['capabilities'] = capabilities;
    _emitMembers(cid);
  }

  @override
  Future<void> appendWrappedCcks(
      String cid, String uid, Map<int, Map<String, String>> boxes) async {
    _append(cid, uid, boxes);
    _emitMembers(cid);
  }

  /// The rules' append-only contract: existing versions are never rewritten.
  void _append(String cid, String uid, Map<int, Map<String, String>> boxes) {
    final doc = members[cid]?[uid];
    if (doc == null) throw StateError('no member $uid in $cid');
    final wrapped = (doc['wrappedCcks'] as Map).cast<String, dynamic>();
    for (final MapEntry(key: version, value: box) in boxes.entries) {
      wrapped['$version'] = box;
    }
    doc['wrappedCcks'] = wrapped;
  }

  // ---- invites --------------------------------------------------------------

  @override
  Future<void> createInvite(
      String cid, String tokenId, Map<String, dynamic> data) async {
    (invites[cid] ??= {})[tokenId] = {
      ...data,
      'createdAt': DateTime.now().toUtc(),
    };
    _emitInvites(cid);
  }

  @override
  Future<Map<String, dynamic>?> readInvite(String cid, String tokenId) async =>
      invites[cid]?[tokenId];

  @override
  Future<Map<String, Map<String, dynamic>>> listInvites(String cid) async =>
      {for (final e in (invites[cid] ?? const {}).entries) e.key: Map.of(e.value)};

  @override
  Stream<Map<String, Map<String, dynamic>>> watchInvites(String cid) {
    final c = _inviteStreams.putIfAbsent(cid,
        () => StreamController<Map<String, Map<String, dynamic>>>.broadcast());
    scheduleMicrotask(() => _emitInvites(cid));
    return c.stream;
  }

  @override
  Future<void> deleteInvite(String cid, String tokenId) async {
    invites[cid]?.remove(tokenId);
    _emitInvites(cid);
  }

  @override
  Future<void> redeemInvite({
    required String cid,
    required String uid,
    required String tokenId,
    required Map<String, dynamic> memberData,
  }) async {
    // Single-use, atomically: the real rules make the create conditional on
    // this same delete, so the fake refuses a redemption of a gone invite.
    if (invites[cid]?[tokenId] == null) {
      throw StateError('invite $tokenId is gone (already redeemed?)');
    }
    if (members[cid]?[uid] != null) {
      throw StateError('$uid is already a member of $cid');
    }
    (members[cid] ??= {})[uid] = {
      ...memberData,
      'createdAt': DateTime.now().toUtc(),
    };
    invites[cid]!.remove(tokenId);
    _emitMembers(cid);
    _emitInvites(cid);
  }

  // ---- rotation -------------------------------------------------------------

  @override
  Future<void> rotateKey({
    required String cid,
    required int newKeyVersion,
    required Map<String, Map<String, String>> wrappedForMember,
    Iterable<String> removeMemberUids = const [],
    Iterable<String> deleteInviteIds = const [],
  }) async {
    rotations.add((
      version: newKeyVersion,
      sealedFor: wrappedForMember.keys.toSet(),
      removed: removeMemberUids.toSet(),
      invitesDeleted: deleteInviteIds.toSet(),
    ));
    for (final MapEntry(key: uid, value: box) in wrappedForMember.entries) {
      _append(cid, uid, {newKeyVersion: box});
    }
    for (final uid in removeMemberUids) {
      members[cid]?.remove(uid);
    }
    for (final id in deleteInviteIds) {
      invites[cid]?.remove(id);
    }
    (congregations[cid] ??= {})['keyVersion'] = newKeyVersion;
    _emitMembers(cid);
    _emitInvites(cid);
  }

  // ---- streams --------------------------------------------------------------

  void _emitMembers(String cid) {
    final c = _memberStreams[cid];
    if (c != null && !c.isClosed) {
      c.add([for (final m in (members[cid] ?? const {}).values) Map.of(m)]);
    }
  }

  void _emitInvites(String cid) {
    final c = _inviteStreams[cid];
    if (c != null && !c.isClosed) {
      c.add({
        for (final e in (invites[cid] ?? const {}).entries) e.key: Map.of(e.value),
      });
    }
  }

  Future<void> dispose() async {
    for (final c in [..._memberStreams.values, ..._inviteStreams.values]) {
      await c.close();
    }
  }
}
