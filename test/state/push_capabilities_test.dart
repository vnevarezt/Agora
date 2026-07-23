// The three-state resolution the sync engine's write filter and the UI gate
// both read from (lib/state/sync_provider.dart): a null "don't filter" for a
// local or still-loading congregation, real capabilities for a member, and
// read-only for a revoked one.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/models/member_capabilities.dart';
import 'package:jw_program/models/membership.dart';
import 'package:jw_program/state/sync_provider.dart';

void main() {
  Membership member(String cid, MemberCapabilities caps) => Membership(
      congregationId: cid, uid: 'me', capabilities: caps, keyVersion: 1);

  // A stream that never emits keeps the provider in AsyncLoading.
  Stream<T> pending<T>() => StreamController<T>().stream;

  // Builds a container overriding the two source streams, subscribes so the
  // streams start, and pumps the event loop so any concrete `Stream.value`
  // emission is applied before the derived providers are read (a `pending()`
  // stream simply stays in AsyncLoading).
  Future<ProviderContainer> build({
    Stream<Set<String>>? shared,
    Stream<List<Membership>>? memberships,
  }) async {
    final c = ProviderContainer(overrides: [
      sharedCongregationIdsProvider.overrideWith((ref) => shared ?? pending()),
      myMembershipsProvider.overrideWith((ref) => memberships ?? pending()),
    ]);
    c.listen(sharedCongregationIdsProvider, (_, _) {});
    c.listen(myMembershipsProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    return c;
  }

  const cid = 'c1';
  const caps = MemberCapabilities(admin: true, people: true);

  test('shared set still loading → null (do not filter)', () async {
    final c = await build(memberships: Stream.value([member(cid, caps)]));
    addTearDown(c.dispose);
    expect(c.read(pushCapabilitiesProvider(cid)), isNull);
  });

  test('never shared → null (local congregation)', () async {
    final c = await build(
      shared: Stream.value(const {}),
      memberships: Stream.value(const []),
    );
    addTearDown(c.dispose);
    expect(c.read(pushCapabilitiesProvider(cid)), isNull);
  });

  test('member → their capabilities', () async {
    final c = await build(
      shared: Stream.value(const {cid}),
      memberships: Stream.value([member(cid, caps)]),
    );
    addTearDown(c.dispose);
    final resolved = c.read(pushCapabilitiesProvider(cid));
    expect(resolved?.admin, isTrue);
    expect(resolved?.people, isTrue);
  });

  test('shared but memberships still loading → null (do not filter)', () async {
    final c = await build(shared: Stream.value(const {cid}));
    addTearDown(c.dispose);
    expect(c.read(pushCapabilitiesProvider(cid)), isNull);
  });

  test('revoked (shared, no membership) → read-only', () async {
    final c = await build(
      shared: Stream.value(const {cid}),
      memberships: Stream.value(const []),
    );
    addTearDown(c.dispose);
    final resolved = c.read(pushCapabilitiesProvider(cid));
    expect(resolved, isNotNull);
    expect(resolved!.canEditAnything, isFalse);
  });

  test('rightsProvider: null reads as founder, revoked as read-only',
      () async {
    final local = await build(); // both loading → null → founder
    addTearDown(local.dispose);
    expect(local.read(rightsProvider(cid)).admin, isTrue);

    final revoked = await build(
      shared: Stream.value(const {cid}),
      memberships: Stream.value(const []),
    );
    addTearDown(revoked.dispose);
    expect(revoked.read(rightsProvider(cid)).canEditAnything, isFalse);
  });
}
