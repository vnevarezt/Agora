// The cloud → local teardown over the Firestore fakes: what gets deleted, what
// survives, and the guards that stand between the user and a half-synced wipe.
// Only the sync controller is stubbed — the key services, the teardown and the
// session controller are the real ones.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agora/data/db/app_database.dart';
import 'package:agora/data/db/db_key_manager.dart';
import 'package:agora/data/sync/cck_service.dart' show SharingException;
import 'package:agora/models/member_capabilities.dart';
import 'package:agora/models/membership.dart';
import 'package:agora/state/auth_session.dart';
import 'package:agora/state/cloud_auth.dart';
import 'package:agora/state/db_provider.dart';
import 'package:agora/state/sync_controller.dart';
import 'package:agora/state/sync_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_key_docs.dart';
import '../helpers/in_memory_transport.dart';
import '../helpers/map_key_store.dart';

const _uid = 'me';
const _cid = 'c1';

class _StubSync extends SyncController {
  _StubSync(this.status);

  final SyncStatus status;
  int pauses = 0;
  int resumes = 0;

  @override
  SyncStatus build() => status;

  @override
  Future<void> syncNow() async {}

  @override
  void pause() => pauses++;

  @override
  void resume({Iterable<String> keepLocal = const []}) => resumes++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeKeyDocs docs;
  late InMemoryTransport transport;
  late MapKeyStore syncStore;
  late MapKeyStore dbStore;
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    docs = FakeKeyDocs();
    transport = InMemoryTransport();
    syncStore = MapKeyStore();
    dbStore = MapKeyStore();
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    addTearDown(docs.dispose);
  });

  void seedCongregation(Map<String, MemberCapabilities> members) {
    docs.congregations[_cid] = {'createdBy': _uid, 'keyVersion': 1};
    docs.members[_cid] = {
      for (final MapEntry(key: uid, value: caps) in members.entries)
        uid: {
          'uid': uid,
          'pubKey': 'pk-$uid',
          'capabilities': caps.toMap(),
          'wrappedCcks': {'1': <String, String>{}},
          'status': 'active',
        },
    };
    transport.docs[_cid] = {};
    // The cached keyring the teardown has to drop from the keychain.
    syncStore.data['jw_program.sync.cck.$_uid.$_cid'] = '{"1":"key"}';
  }

  Future<(ProviderContainer, _StubSync)> build({
    SyncStatus status = const SyncStatus(phase: SyncPhase.idle),
    List<Membership> memberships = const [
      Membership(
          congregationId: _cid,
          uid: _uid,
          capabilities: MemberCapabilities.founder,
          keyVersion: 1),
    ],
  }) async {
    final sync = _StubSync(status);
    final container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      dbKeyManagerProvider.overrideWithValue(
          DbKeyManager(store: dbStore, params: testKdfParams)),
      firebaseAppProvider.overrideWith((ref) => Future.value(null)),
      cloudAuthProvider.overrideWith((ref) => Future.value(null)),
      syncKeyStoreProvider.overrideWithValue(syncStore),
      keyDocsProvider.overrideWithValue(docs),
      syncTransportProvider.overrideWithValue(transport),
      syncUidProvider.overrideWithValue(_uid),
      myMembershipsProvider.overrideWith((ref) => Stream.value(memberships)),
      syncControllerProvider.overrideWith(() => sync),
    ]);
    addTearDown(container.dispose);

    // A real cloud session: created locally, then migrated up, so the DEK the
    // downgrade re-wraps is the one that actually opens the database.
    final session = container.read(authSessionProvider.notifier);
    for (var i = 0;
        i < 100 && container.read(authSessionProvider) is SessionLoading;
        i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await session.createLocalProfile('Ana', 'pw-123456');
    await session.upgradeToCloud();
    await db.into(db.syncState).insert(SyncStateCompanion.insert(
        congregationId: _cid, updatedAt: DateTime.now().toUtc()));
    return (container, sync);
  }

  Future<int> syncStateRows() async =>
      (await db.select(db.syncState).get()).length;

  test('sole member: wipes the space, keeps the local data and the key',
      () async {
    seedCongregation({_uid: MemberCapabilities.founder});
    final (container, sync) = await build();
    final dek =
        (container.read(authSessionProvider) as SessionUnlocked).dekHex;

    await container.read(downgradeToLocalProvider)('Beto', 'pw-abcdefg');

    expect(docs.congregations.containsKey(_cid), isFalse);
    expect(docs.members[_cid], isEmpty);
    expect(transport.docs.containsKey(_cid), isFalse);
    expect(await syncStateRows(), 0);
    expect(sync.pauses, 1);

    final state = container.read(authSessionProvider) as SessionUnlocked;
    expect(state.mode, AccountMode.local);
    expect(state.profileName, 'Beto');
    expect(
        await DbKeyManager(store: dbStore, params: testKdfParams)
            .unlock('pw-abcdefg'),
        dek);
  });

  // End state only: the live Firestore query goes empty the moment the member
  // doc is deleted, and this harness's stream does not, so it cannot reproduce
  // the ordering that made the teardown miss these. The cids are passed
  // explicitly for that reason.
  test('the cached keyring leaves the keychain', () async {
    seedCongregation({_uid: MemberCapabilities.founder});
    final (container, _) = await build();

    await container.read(downgradeToLocalProvider)('Beto', 'pw-abcdefg');

    expect(syncStore.data.keys.where((k) => k.contains('.cck.')), isEmpty);
  });

  test('others remain: leaves without touching their space', () async {
    seedCongregation({
      _uid: const MemberCapabilities(people: true),
      'other': MemberCapabilities.founder,
    });
    final (container, _) = await build(memberships: const [
      Membership(
          congregationId: _cid,
          uid: _uid,
          capabilities: MemberCapabilities(people: true),
          keyVersion: 1),
    ]);

    await container.read(downgradeToLocalProvider)('Beto', 'pw-abcdefg');

    expect(docs.congregations.containsKey(_cid), isTrue);
    expect(docs.members[_cid]!.keys, ['other']);
    expect(transport.docs.containsKey(_cid), isTrue);
  });

  test('sole admin with other members: refuses and deletes nothing', () async {
    seedCongregation({
      _uid: MemberCapabilities.founder,
      'other': const MemberCapabilities(people: true),
    });
    final (container, sync) = await build();

    await expectLater(
      container.read(downgradeToLocalProvider)('Beto', 'pw-abcdefg'),
      throwsA(isA<AccountDeletionBlocked>()),
    );
    expect(docs.congregations.containsKey(_cid), isTrue);
    expect(docs.members[_cid]!.length, 2);
    expect(sync.pauses, 0);
    expect(container.read(authSessionProvider), isA<SessionUnlocked>());
    expect((container.read(authSessionProvider) as SessionUnlocked).mode,
        AccountMode.cloud);
  });

  // The guard that stands between the user and a half-synced wipe. `syncing`
  // is the subtle one: syncNow returns immediately when a push or pull is
  // already in flight, so it must never read as success.
  for (final (phase, reason, forceable) in const [
    (SyncPhase.offline, 'offline', false),
    (SyncPhase.syncing, 'syncBusy', false),
    (SyncPhase.error, 'syncIncomplete', true),
  ]) {
    test('an unconfirmed drain ($reason) deletes nothing', () async {
      seedCongregation({_uid: MemberCapabilities.founder});
      final (container, _) = await build(status: SyncStatus(phase: phase));

      await expectLater(
        container.read(downgradeToLocalProvider)('Beto', 'pw-abcdefg'),
        throwsA(isA<SharingException>()
            .having((e) => e.reason, 'reason', reason)),
      );
      expect(docs.congregations.containsKey(_cid), isTrue);
      expect(await syncStateRows(), 1);
    });

    test('force ${forceable ? 'overrides' : 'does not override'} $reason',
        () async {
      seedCongregation({_uid: MemberCapabilities.founder});
      final (container, _) = await build(status: SyncStatus(phase: phase));
      final run = container.read(downgradeToLocalProvider)(
          'Beto', 'pw-abcdefg',
          force: true);

      if (forceable) {
        await run;
        expect(docs.congregations.containsKey(_cid), isFalse);
      } else {
        await expectLater(run, throwsA(isA<SharingException>()));
        expect(docs.congregations.containsKey(_cid), isTrue);
      }
    });
  }
}
