import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/sync/congregation_teardown.dart';
import 'package:jw_program/models/member_capabilities.dart';

import '../helpers/fake_key_docs.dart';
import '../helpers/in_memory_transport.dart';

void main() {
  // Seeds a congregation (bypassing rules, like the fixtures do): meta, one
  // item, an invite, and the given members.
  Future<void> seed(
    FakeKeyDocs docs,
    InMemoryTransport transport,
    String cid,
    Map<String, MemberCapabilities> members,
  ) async {
    docs.congregations[cid] = {'createdBy': 'me', 'keyVersion': 1};
    docs.members[cid] = {
      for (final MapEntry(key: uid, value: caps) in members.entries)
        uid: {
          'uid': uid,
          'pubKey': 'pk-$uid',
          'capabilities': caps.toMap(),
          'wrappedCcks': {'1': {}},
          'status': 'active',
        },
    };
    docs.invites[cid] = {
      't1': {'capabilities': const MemberCapabilities().toMap()}
    };
    transport.docs[cid] = {};
    transport.activity[cid] = {'scopes': <String, String>{}};
  }

  group('CongregationTeardown', () {
    late FakeKeyDocs docs;
    late InMemoryTransport transport;
    late CongregationTeardown teardown;

    setUp(() {
      docs = FakeKeyDocs();
      transport = InMemoryTransport();
      teardown = CongregationTeardown(docs, transport, uid: 'me');
    });

    test('wipe deletes everything, my own member doc LAST', () async {
      await seed(docs, transport, 'c1', {
        'me': MemberCapabilities.founder,
        'bob': const MemberCapabilities(people: true),
      });

      final deletions = <String>[];
      docs.onDeleteMember = (uid) => deletions.add(uid);

      await teardown.wipe('c1');

      // Every collection gone.
      expect(docs.congregations, isNot(contains('c1')));
      expect(docs.members['c1'], anyOf(isNull, isEmpty));
      expect(docs.invites['c1'], anyOf(isNull, isEmpty));
      expect(transport.docs, isNot(contains('c1')));
      expect(transport.activity, isNot(contains('c1')));
      // Order: other members before me, and my own doc is the final delete.
      expect(deletions, ['bob', 'me']);
    });

    test('leave deletes only my own member doc', () async {
      await seed(docs, transport, 'c1', {
        'me': const MemberCapabilities(people: true),
        'admin': MemberCapabilities.founder,
      });

      await teardown.leave('c1');

      expect(docs.members['c1'], isNot(contains('me')));
      expect(docs.members['c1'], contains('admin'));
      // Nothing else touched.
      expect(docs.congregations, contains('c1'));
      expect(transport.docs, contains('c1'));
    });
  });

  group('planAccountDeletion', () {
    MemberRole role(String uid, {bool admin = false}) =>
        (memberUid: uid, admin: admin);

    test('sole member & admin → wipe', () {
      final plan = planAccountDeletion('me', {
        'c1': [role('me', admin: true)],
      });
      expect(plan.wipe, ['c1']);
      expect(plan.leave, isEmpty);
      expect(plan.blocked, isEmpty);
    });

    test('others remain with another admin → leave', () {
      final plan = planAccountDeletion('me', {
        'c1': [role('me', admin: true), role('bob', admin: true)],
      });
      expect(plan.leave, ['c1']);
      expect(plan.wipe, isEmpty);
      expect(plan.blocked, isEmpty);
    });

    test('non-admin member with others → leave', () {
      final plan = planAccountDeletion('me', {
        'c1': [role('me'), role('admin', admin: true)],
      });
      expect(plan.leave, ['c1']);
      expect(plan.blocked, isEmpty);
    });

    test('sole admin with other members → blocked', () {
      final plan = planAccountDeletion('me', {
        'c1': [role('me', admin: true), role('bob')],
      });
      expect(plan.blocked, ['c1']);
      expect(plan.wipe, isEmpty);
      expect(plan.leave, isEmpty);
    });

    test('sole member, not admin → leave (cannot wipe without admin)', () {
      final plan = planAccountDeletion('me', {
        'c1': [role('me')],
      });
      expect(plan.leave, ['c1']);
      expect(plan.wipe, isEmpty);
    });

    test('mixed congregations sort into the right buckets', () {
      final plan = planAccountDeletion('me', {
        'solo': [role('me', admin: true)],
        'shared': [role('me', admin: true), role('bob', admin: true)],
        'stuck': [role('me', admin: true), role('carol')],
      });
      expect(plan.wipe, ['solo']);
      expect(plan.leave, ['shared']);
      expect(plan.blocked, ['stuck']);
    });
  });
}
