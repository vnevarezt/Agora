// What the upgrade wizard reads to know the upload is done. A congregation's
// cloud space appears long before its contents land, so "every congregation is
// shared" is not enough on its own — the outbox has to be empty too.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agora/models/congregation.dart';
import 'package:agora/state/dashboard_provider.dart';
import 'package:agora/state/restore_provider.dart';
import 'package:agora/state/sync_controller.dart';
import 'package:agora/state/sync_provider.dart';

Congregation _congregation(String id) =>
    Congregation(id: id, name: id, number: '1', color: 0);

class _StubSync extends SyncController {
  _StubSync(this.pending);

  final int pending;

  @override
  SyncStatus build() => SyncStatus(pendingOutbox: pending);
}

void main() {
  Future<ProviderContainer> build({
    String? uid = 'me',
    List<String> local = const ['c1', 'c2'],
    Set<String> shared = const {},
    int pendingOutbox = 0,
  }) async {
    final c = ProviderContainer(overrides: [
      syncUidProvider.overrideWithValue(uid),
      congregationsStreamProvider.overrideWith(
          (ref) => Stream.value([for (final id in local) _congregation(id)])),
      sharedCongregationIdsProvider.overrideWith((ref) => Stream.value(shared)),
      syncControllerProvider.overrideWith(() => _StubSync(pendingOutbox)),
    ]);
    addTearDown(c.dispose);
    c.listen(congregationsStreamProvider, (_, _) {});
    c.listen(sharedCongregationIdsProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    return c;
  }

  test('counts the congregations that already have a cloud space', () async {
    final c = await build(shared: const {'c1'}, pendingOutbox: 3);
    expect(c.read(cloudUploadProgressProvider), (done: 1, total: 2));
  });

  test('spaces created but outbox still draining is not done', () async {
    final c = await build(shared: const {'c1', 'c2'}, pendingOutbox: 5);
    expect(c.read(cloudUploadProgressProvider), (done: 2, total: 2));
  });

  test('every space created and the outbox drained is done', () async {
    final c = await build(shared: const {'c1', 'c2'});
    expect(c.read(cloudUploadProgressProvider), isNull);
  });

  test('no cloud session: nothing to report', () async {
    final c = await build(uid: null, shared: const {'c1'}, pendingOutbox: 3);
    expect(c.read(cloudUploadProgressProvider), isNull);
  });

  test('a device with no congregations has nothing to upload', () async {
    final c = await build(local: const []);
    expect(c.read(cloudUploadProgressProvider), isNull);
  });
}
