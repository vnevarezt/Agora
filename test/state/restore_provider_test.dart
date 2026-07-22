// initialRestoreProvider: decides whether a freshly signed-in device is still
// pulling cloud data it has never seen, and how far along it is. "Missing" is
// measured against the local congregation rows, never the pull cursor.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/models/congregation.dart';
import 'package:jw_program/models/member_capabilities.dart';
import 'package:jw_program/models/membership.dart';
import 'package:jw_program/state/dashboard_provider.dart';
import 'package:jw_program/state/restore_provider.dart';
import 'package:jw_program/state/sync_provider.dart';

void main() {
  Congregation cong(String id) =>
      Congregation(id: id, name: id, number: '', color: 0);

  Membership mem(String id) => Membership(
        congregationId: id,
        uid: 'u1',
        capabilities: MemberCapabilities.founder,
        keyVersion: 0,
      );

  // null list = the stream is still loading (never emits).
  Stream<List<T>> streamOf<T>(List<T>? value) => value == null
      ? Stream<List<T>>.fromFuture(Completer<List<T>>().future)
      : Stream<List<T>>.value(value);

  Future<InitialRestore?> compute({
    String? uid = 'u1',
    List<Congregation>? congregations = const [],
    List<Membership>? memberships = const [],
  }) async {
    final c = ProviderContainer(overrides: [
      syncUidProvider.overrideWithValue(uid),
      congregationsStreamProvider.overrideWith((ref) => streamOf(congregations)),
      myMembershipsProvider.overrideWith((ref) => streamOf(memberships)),
    ]);
    addTearDown(c.dispose);
    final sub = c.listen(initialRestoreProvider, (_, _) {});
    addTearDown(sub.close);
    // Let the value streams emit; the loading ones stay pending. Memberships
    // is watched only after the local stream has a value, so its subscription
    // (and emission) lands a microtask stage later — pump enough to cover it.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return c.read(initialRestoreProvider);
  }

  test('no cloud session → nothing to restore', () async {
    expect(await compute(uid: null), isNull);
  });

  test('memberships loading + empty device → indeterminate', () async {
    expect(
      await compute(congregations: const [], memberships: null),
      (done: 0, total: 0),
    );
  });

  test('memberships loading + device already has data → no banner', () async {
    expect(
      await compute(congregations: [cong('a')], memberships: null),
      isNull,
    );
  });

  test('local stream still loading → no banner (skeleton covers it)', () async {
    expect(
      await compute(congregations: null, memberships: [mem('a')]),
      isNull,
    );
  });

  test('partial restore reports done/total', () async {
    expect(
      await compute(
        congregations: [cong('a')],
        memberships: [mem('a'), mem('b'), mem('c')],
      ),
      (done: 1, total: 3),
    );
  });

  test('all cloud congregations present locally → done', () async {
    expect(
      await compute(congregations: [cong('a')], memberships: [mem('a')]),
      isNull,
    );
  });

  test('founder with a local-only congregation and no memberships → done',
      () async {
    expect(
      await compute(congregations: [cong('x')], memberships: const []),
      isNull,
    );
  });
}
