import 'key_docs_gateway.dart';
import 'sync_transport.dart';

/// Hard-deletes a congregation's cloud space, or just this member's own doc.
/// Firestore does not cascade, and the rules gate every teardown delete on
/// `isAdmin(cid)` — which reads the CALLER's member doc — so the order is
/// load-bearing: everything else goes first, the caller's own member doc LAST.
///
/// Pure (gateway + transport, no keychain): the keyring `forget` and local
/// bookkeeping live in the calling provider.
class CongregationTeardown {
  CongregationTeardown(this._docs, this._transport, {required this.uid});

  final KeyDocsGateway _docs;
  final SyncTransport _transport;
  final String uid;

  /// Leaves a congregation others still run: delete only my own member doc
  /// (self-delete is always allowed). Nothing else is touched.
  Future<void> leave(String cid) => _docs.deleteMemberDoc(cid, uid);

  /// Full teardown, in the rules-safe order. The caller must be an admin and
  /// still hold their member doc throughout (it is deleted last). Idempotent:
  /// a re-run after an interruption just finds fewer docs.
  Future<void> wipe(String cid) async {
    await _transport.deleteAllItems(cid); // items + meta/activity
    for (final id in (await _docs.listInvites(cid)).keys) {
      await _docs.deleteInvite(cid, id);
    }
    for (final member in await _docs.listMembers(cid)) {
      final memberUid = member['uid'] as String?;
      if (memberUid == null || memberUid == uid) continue; // mine goes last
      await _docs.deleteMemberDoc(cid, memberUid);
    }
    await _docs.deleteCongregationDoc(cid);
    await _docs.deleteMemberDoc(cid, uid); // LAST: isAdmin() reads this
  }
}

/// One member's relevance to the deletion decision: are they me, and are they
/// an admin.
typedef MemberRole = ({String memberUid, bool admin});

/// What to do with each congregation when the [uid] account is deleted, from
/// the member landscape. Pure, so it's unit-testable without Firebase.
///
///  - `wipe`: I'm the sole member AND an admin → tear the whole space down.
///  - `leave`: others remain and either I'm not the last admin or not an admin
///    → just delete my own member doc.
///  - `blocked`: I'm the sole admin but other members remain → refuse; deleting
///    would strand them (nobody could rotate, invite or clean up).
class AccountDeletionPlan {
  const AccountDeletionPlan(
      {required this.wipe, required this.leave, required this.blocked});

  final List<String> wipe;
  final List<String> leave;
  final List<String> blocked;
}

AccountDeletionPlan planAccountDeletion(
    String uid, Map<String, List<MemberRole>> membersByCongregation) {
  final wipe = <String>[], leave = <String>[], blocked = <String>[];
  for (final MapEntry(key: cid, value: members) in membersByCongregation.entries) {
    final iAmAdmin = members.any((m) => m.memberUid == uid && m.admin);
    final others = members.where((m) => m.memberUid != uid).toList();
    if (others.isEmpty) {
      (iAmAdmin ? wipe : leave).add(cid);
    } else if (iAmAdmin && !others.any((m) => m.admin)) {
      blocked.add(cid);
    } else {
      leave.add(cid);
    }
  }
  return AccountDeletionPlan(wipe: wipe, leave: leave, blocked: blocked);
}
