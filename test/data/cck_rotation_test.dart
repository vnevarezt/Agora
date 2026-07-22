import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/sync/cck_service.dart';
import 'package:jw_program/data/sync/invite_code.dart';
import 'package:jw_program/data/sync/user_key_service.dart';
import 'package:jw_program/models/member_capabilities.dart';

import '../helpers/fake_key_docs.dart';
import '../helpers/map_key_store.dart';

/// One signed-in account on one device.
class _Device {
  _Device(this.docs, this.uid) {
    store = MapKeyStore();
    keys = UserKeyService(store, docs, uid: uid);
    cck = CckService(store, docs, keys, uid: uid);
  }

  final FakeKeyDocs docs;
  final String uid;
  late final MapKeyStore store;
  late final UserKeyService keys;
  late final CckService cck;

  Future<void> ready() => keys.ensureAvailable();
}

const _viewer = MemberCapabilities(people: true);

void main() {
  late FakeKeyDocs docs;
  late _Device admin;

  setUp(() async {
    docs = FakeKeyDocs();
    admin = _Device(docs, 'admin');
    await admin.ready();
    await admin.cck.createCongregationSpace('c1', displayName: 'Ana');
  });

  Future<_Device> join(InviteCode code, String uid) async {
    final device = _Device(docs, uid);
    await device.cck.redeemInvite(code, displayName: uid);
    return device;
  }

  test('an invitee redeems the code and recovers the WHOLE keyring',
      () async {
    // Two versions exist before anyone is invited: the newcomer must be able
    // to read the history, not just what happens next.
    await admin.cck.rotateAndRevoke('c1');
    final adminKeyring = (await admin.cck.keyringFor('c1'))!;
    expect(adminKeyring.keys.keys.toSet(), {1, 2});

    final code = await admin.cck.createInvite('c1', capabilities: _viewer);
    final bob = await join(code, 'bob');

    final bobKeyring = (await bob.cck.keyringFor('c1'))!;
    expect(bobKeyring.keys.keys.toSet(), {1, 2});
    for (final v in adminKeyring.keys.keys) {
      expect(bobKeyring.keys[v], adminKeyring.keys[v]);
    }
    // Capabilities are copied verbatim from the invite (the rules compare
    // the two maps, so anything else would be rejected server-side).
    final member = docs.members['c1']!['bob']!;
    expect((member['capabilities'] as Map)['people'], true);
    expect((member['capabilities'] as Map)['admin'], false);
    expect(member['addedBy'], 'admin');
    expect(member['inviteId'], code.tokenId);
  });

  test('an invite is single-use and disappears when redeemed', () async {
    final code = await admin.cck.createInvite('c1', capabilities: _viewer);
    expect(docs.invites['c1'], contains(code.tokenId));

    await join(code, 'bob');
    expect(docs.invites['c1'], isNot(contains(code.tokenId)));

    // A second person with the same code gets a message, not a crash.
    final carol = _Device(docs, 'carol');
    await expectLater(
      carol.cck.redeemInvite(code),
      throwsA(isA<SharingException>()
          .having((e) => e.reason, 'reason', 'inviteMissing')),
    );
  });

  test('an expired invite is refused with a distinguishable reason', () async {
    final code = await admin.cck
        .createInvite('c1', capabilities: _viewer, ttl: Duration.zero);
    final bob = _Device(docs, 'bob');

    await expectLater(
      bob.cck.redeemInvite(code),
      throwsA(isA<SharingException>()
          .having((e) => e.reason, 'reason', 'inviteExpired')),
    );
  });

  test('an existing member is told so instead of hitting the rules', () async {
    final code = await admin.cck.createInvite('c1', capabilities: _viewer);
    await expectLater(
      admin.cck.redeemInvite(code),
      throwsA(isA<SharingException>()
          .having((e) => e.reason, 'reason', 'alreadyMember')),
    );
  });

  test('rotation appends a version without touching the old ones', () async {
    final before = (await admin.cck.keyringFor('c1'))!;
    final v1 = before.currentKey;

    final after = await admin.cck.rotateAndRevoke('c1');

    expect(after.keys.keys.toSet(), {1, 2});
    expect(after.keys[1], v1, reason: 'history must stay readable');
    expect(after.currentVersion, 2);
    expect(after.currentKey, isNot(v1));
    expect(docs.congregations['c1']!['keyVersion'], 2);
  });

  test('survivors get the new version, the revoked member gets nothing',
      () async {
    final bobCode = await admin.cck.createInvite('c1', capabilities: _viewer);
    final bob = await join(bobCode, 'bob');
    final carolCode = await admin.cck.createInvite('c1', capabilities: _viewer);
    await join(carolCode, 'carol');

    await admin.cck.rotateAndRevoke('c1', removeUids: ['bob']);

    // Carol survives: a fresh device of hers recovers v1 AND v2.
    final carolAgain = _Device(docs, 'carol');
    final carolKeyring = (await carolAgain.cck.keyringFor('c1'))!;
    expect(carolKeyring.keys.keys.toSet(), {1, 2});

    // Bob is gone from the collection entirely.
    expect(docs.members['c1'], isNot(contains('bob')));
    // His cached keyring still opens history — that data is already on his
    // device — but a fresh device of his recovers nothing.
    expect((await bob.cck.keyringFor('c1'))!.keys.keys.toSet(), {1});
    expect(await _Device(docs, 'bob').cck.keyringFor('c1'), isNull);

    final rotation = docs.rotations.single;
    expect(rotation.version, 2);
    expect(rotation.sealedFor, {'admin', 'carol'});
    expect(rotation.removed, {'bob'});
  });

  test('rotation kills pending invites in the same batch', () async {
    // A pending invite's wrappedKeyring is immutable and frozen at v1: left
    // alive, its redeemer would join blind to everything written after.
    final stale = await admin.cck.createInvite('c1', capabilities: _viewer);
    final bobCode = await admin.cck.createInvite('c1', capabilities: _viewer);
    final bob = await join(bobCode, 'bob');

    await admin.cck.rotateAndRevoke('c1', removeUids: ['bob']);

    expect(docs.invites['c1'], isEmpty);
    expect(docs.rotations.single.invitesDeleted, contains(stale.tokenId));
    await expectLater(
      _Device(docs, 'dave').cck.redeemInvite(stale),
      throwsA(isA<SharingException>()),
    );
    expect(bob.uid, 'bob');
  });

  test('an admin can revoke themselves and rotate in the same batch',
      () async {
    // The only way a departing admin can rotate at all: `isAdmin` reads
    // their PRE-batch doc, so the self-delete and the bump commit together.
    final code = await admin.cck.createInvite('c1', capabilities: _viewer);
    await join(code, 'bob');

    await admin.cck.rotateAndRevoke('c1', removeUids: ['admin']);

    expect(docs.members['c1']!.keys, ['bob']);
    expect(docs.rotations.single.sealedFor, {'bob'});
    expect(docs.congregations['c1']!['keyVersion'], 2);
    // We stop holding a key we are no longer entitled to.
    expect(await admin.cck.keyringFor('c1'), isNull);
  });

  test('a member with an unreadable public key aborts the rotation by name',
      () async {
    final code = await admin.cck.createInvite('c1', capabilities: _viewer);
    await join(code, 'bob');
    docs.members['c1']!['bob']!['pubKey'] = 'not-base64!!';

    // Skipping Bob would leave a permanent hole in his keyring — he'd
    // silently stop reading new writes.
    await expectLater(
      admin.cck.rotateAndRevoke('c1'),
      throwsA(isA<SharingException>()
          .having((e) => e.reason, 'reason', 'badMemberKey')
          .having((e) => e.message, 'message', contains('bob'))),
    );
    expect(docs.rotations, isEmpty);
    expect(docs.congregations['c1']!['keyVersion'], 1);
  });

  test('reconciliation repairs a hole in the MIDDLE of a keyring', () async {
    final code = await admin.cck.createInvite('c1', capabilities: _viewer);
    await join(code, 'bob');
    await admin.cck.rotateAndRevoke('c1'); // v2
    await admin.cck.rotateAndRevoke('c1'); // v3

    // Bob missed v2 only — the kind of gap a max version can never see.
    (docs.members['c1']!['bob']!['wrappedCcks'] as Map).remove('2');
    final holed = (await _Device(docs, 'bob').cck.keyringFor('c1'))!;
    expect(holed.keys.keys.toSet(), {1, 3});

    expect(await admin.cck.reconcileKeyrings('c1'), 1);

    final repaired = (await _Device(docs, 'bob').cck.keyringFor('c1'))!;
    expect(repaired.keys.keys.toSet(), {1, 2, 3});
    final adminKeyring = (await admin.cck.keyringFor('c1'))!;
    for (final v in [1, 2, 3]) {
      expect(repaired.keys[v], adminKeyring.keys[v]);
    }
  });

  test('someone who joins mid-rotation is repaired by the same call',
      () async {
    // The one moment a gap can open: the member list is read, THEN the
    // batch commits — a redemption in between lands a doc holding every
    // version except the one being minted.
    final code = await admin.cck.createInvite('c1', capabilities: _viewer);
    final latecomer = _Device(docs, 'dave');
    docs.onListMembers = () async {
      docs.onListMembers = null; // only race the first read
      await latecomer.cck.redeemInvite(code, displayName: 'Dave');
    };

    await admin.cck.rotateAndRevoke('c1');

    expect(docs.rotations.single.sealedFor, isNot(contains('dave')));
    // ...but the post-commit reconciliation caught up with them.
    final daveKeyring = (await _Device(docs, 'dave').cck.keyringFor('c1'))!;
    expect(daveKeyring.keys.keys.toSet(), {1, 2});
    expect(daveKeyring.keys[2], (await admin.cck.keyringFor('c1'))!.keys[2]);
  });

  test('reconciliation is a no-op when every keyring is contiguous',
      () async {
    final code = await admin.cck.createInvite('c1', capabilities: _viewer);
    await join(code, 'bob');
    await admin.cck.rotateAndRevoke('c1');

    expect(await admin.cck.reconcileKeyrings('c1'), 0);
  });

  test('capabilities can be changed without rotating', () async {
    // Downgrading keeps the keyring: the rules stop their writes, and
    // history they already hold is not a secret we can take back.
    final code = await admin.cck.createInvite('c1', capabilities: _viewer);
    await join(code, 'bob');

    await admin.cck.setMemberCapabilities(
        'c1', 'bob', const MemberCapabilities(editTypes: ['*']));

    final bob = (await admin.cck.listMembers('c1'))
        .firstWhere((m) => m.uid == 'bob');
    expect(bob.capabilities.people, isFalse);
    expect(bob.capabilities.editTypes, ['*']);
    expect(docs.rotations, isEmpty);
    expect(docs.congregations['c1']!['keyVersion'], 1);
  });
}
