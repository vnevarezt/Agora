// The 4b founder flow end-to-end, minus the network: device A sets up sync
// keys, enables cloud on a congregation (mint CCK + create space), pushes the
// seeded outbox; device B (SAME account, new device) unlocks with the
// passphrase, recovers the CCK from the member doc and pulls. Wires the real
// key services + engine over the fakes that stand in for Firestore.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/data/sync/cck_service.dart';
import 'package:jw_program/data/sync/content_crypto.dart';
import 'package:jw_program/data/sync/sync_engine.dart';
import 'package:jw_program/data/sync/sync_seeder.dart';
import 'package:jw_program/data/sync/hlc.dart';
import 'package:jw_program/data/sync/sync_scribe.dart';
import 'package:jw_program/data/sync/user_key_service.dart';
import 'package:jw_program/models/member_capabilities.dart';
import 'package:jw_program/models/person.dart';
import 'package:jw_program/state/dashboard_provider.dart';
import 'package:jw_program/state/db_provider.dart';
import 'package:jw_program/state/people_provider.dart';

import '../helpers/fake_key_docs.dart';
import '../helpers/in_memory_transport.dart';
import '../helpers/map_key_store.dart';


class CloudDevice {
  CloudDevice(
    this.name,
    InMemoryTransport transport,
    FakeKeyDocs docs, {
    required String uid,
  }) {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [dbProvider.overrideWithValue(db)]);
    store = MapKeyStore();
    userKeys = UserKeyService(store, docs, uid: uid);
    cck = CckService(store, docs, userKeys, uid: uid);
    seeder = SyncSeeder(db, SyncScribe(db, HlcClock(name)));
    engine = SyncEngine(db, transport, ContentCrypto(),
        deviceId: name, keyringFor: cck.keyringFor);
  }

  final String name;
  late final AppDatabase db;
  late final ProviderContainer container;
  late final MapKeyStore store;
  late final UserKeyService userKeys;
  late final CckService cck;
  late final SyncSeeder seeder;
  late final SyncEngine engine;

  void dispose() {
    container.dispose();
    db.close();
  }
}

void main() {
  test('founder enables cloud, pushes; a new device recovers and pulls',
      () async {
    final transport = InMemoryTransport();
    final docs = FakeKeyDocs();

    final a = CloudDevice('devA', transport, docs, uid: 'u1');
    addTearDown(a.dispose);

    // Device A: create real data, set up keys, enable cloud, push.
    final cong = await a.container
        .read(congregationsRepositoryProvider)
        .create(name: 'Norte', number: '7');
    await a.container
        .read(peopleRepositoryProvider)
        .save(_person('p1', 'Ana', cong.id));

    await a.userKeys.ensureAvailable();
    await a.cck.createCongregationSpace(cong.id);
    final seeded = await a.seeder.seedCongregation(cong.id);
    expect(seeded, 2); // congregation + person

    final pushed = await a.engine.pushOnce();
    expect(pushed, 2);
    // Server-blind: the plaintext never appears in a blob.
    for (final doc in transport.docs[cong.id]!.values) {
      expect(doc.blob.contains('Ana'), isFalse);
      expect(doc.blob.contains('Norte'), isFalse);
    }

    // Device B: SAME account, new device. Unlock with the passphrase, pull.
    final b = CloudDevice('devB', transport, docs, uid: 'u1');
    addTearDown(b.dispose);
    // Nothing to do: signing in is enough — device B fetches the account's
    // key by itself.

    final page = await b.engine.pullOnce(cong.id);
    expect(page.applied, 2);
    final bPeople = await b.container.read(peopleRepositoryProvider).all();
    expect(bPeople.single.displayName, 'Ana');
  });

  test('a device with no identity at all cannot pull (keyring null)', () async {
    final transport = InMemoryTransport();
    final docs = FakeKeyDocs();
    final a = CloudDevice('devA', transport, docs, uid: 'u1');
    addTearDown(a.dispose);

    final cong = await a.container
        .read(congregationsRepositoryProvider)
        .create(name: 'Sur', number: '1');
    await a.userKeys.ensureAvailable();
    await a.cck.createCongregationSpace(cong.id);
    await a.seeder.seedCongregation(cong.id);
    await a.engine.pushOnce();

    // Device B belongs to a DIFFERENT account, so it has no identity here
    // and is not a member: keyringFor → null and the pull applies nothing.
    final b = CloudDevice('devB', transport, docs, uid: 'someone-else');
    addTearDown(b.dispose);
    final page = await b.engine.pullOnce(cong.id);
    expect(page.fetched, 0);
    expect(page.applied, 0);
  });

  test('an invitee redeems a code and pulls the history that predates them',
      () async {
    final transport = InMemoryTransport();
    final docs = FakeKeyDocs();

    final ana = CloudDevice('devAna', transport, docs, uid: 'ana');
    addTearDown(ana.dispose);
    final cong = await ana.container
        .read(congregationsRepositoryProvider)
        .create(name: 'Norte', number: '7');
    await ana.userKeys.ensureAvailable();
    await ana.cck.createCongregationSpace(cong.id);
    await ana.container
        .read(peopleRepositoryProvider)
        .save(_person('p1', 'Ana', cong.id));
    await ana.seeder.seedCongregation(cong.id);
    await ana.engine.pushOnce();

    // A rotation BEFORE anyone is invited: the newcomer's keyring must span
    // both versions or the older half of the history stays unreadable.
    await ana.cck.rotateAndRevoke(cong.id);
    await ana.container
        .read(peopleRepositoryProvider)
        .save(_person('p2', 'Bea', cong.id));
    await ana.seeder.seedCongregation(cong.id);
    await ana.engine.pushOnce();

    final code = await ana.cck.createInvite(cong.id,
        capabilities: const MemberCapabilities(people: true));

    final bea = CloudDevice('devBea', transport, docs, uid: 'bea');
    addTearDown(bea.dispose);
    await bea.cck.redeemInvite(code, displayName: 'Bea');

    // Redemption alone downloads nothing — the caller must pull explicitly
    // (with a null cursor, nothing else would ever trigger one).
    final page = await bea.engine.pullOnce(cong.id);
    expect(page.cursorHeld, isFalse, reason: 'holds every version');
    expect(
      {
        for (final p in await bea.container.read(peopleRepositoryProvider).all())
          p.displayName,
      },
      {'Ana', 'Bea'},
    );
  });

  test('a revoked member keeps local data and stops receiving new writes',
      () async {
    final transport = InMemoryTransport();
    final docs = FakeKeyDocs();

    final ana = CloudDevice('devAna', transport, docs, uid: 'ana');
    addTearDown(ana.dispose);
    final cong = await ana.container
        .read(congregationsRepositoryProvider)
        .create(name: 'Norte', number: '7');
    await ana.userKeys.ensureAvailable();
    await ana.cck.createCongregationSpace(cong.id);
    await ana.container
        .read(peopleRepositoryProvider)
        .save(_person('p1', 'Ana', cong.id));
    await ana.seeder.seedCongregation(cong.id);
    await ana.engine.pushOnce();

    final code = await ana.cck.createInvite(cong.id,
        capabilities: const MemberCapabilities(people: true));
    final bea = CloudDevice('devBea', transport, docs, uid: 'bea');
    addTearDown(bea.dispose);
    await bea.cck.redeemInvite(code);
    await bea.engine.pullOnce(cong.id);
    expect((await bea.container.read(peopleRepositoryProvider).all()).length, 1);

    await ana.cck.rotateAndRevoke(cong.id, removeUids: ['bea']);
    await ana.container
        .read(peopleRepositoryProvider)
        .save(_person('p2', 'Secreta', cong.id));
    await ana.seeder.seedCongregation(cong.id);
    await ana.engine.pushOnce();

    // Bea's cached keyring still opens what she already had — that data is
    // on her device and revocation can't reach back for it.
    final page = await bea.engine.pullOnce(cong.id);
    expect(page.applied, 0);
    expect(
      (await bea.container.read(peopleRepositoryProvider).all())
          .single
          .displayName,
      'Ana',
    );
    // The new write is opaque to her: the cursor is held, not skipped, so a
    // re-admission would still recover it.
    expect(page.cursorHeld, isTrue);
    expect(page.unknownKeyVersions, {2});

    // And a fresh device of hers recovers nothing at all.
    final beaNew = CloudDevice('devBea2', transport, docs, uid: 'bea');
    addTearDown(beaNew.dispose);
    expect(await beaNew.cck.keyringFor(cong.id), isNull);
    expect((await beaNew.engine.pullOnce(cong.id)).fetched, 0);
  });
}

Person _person(String id, String name, String congregationId) => Person(
      id: id,
      congregationId: congregationId,
      firstName: '',
      lastName: '',
      displayName: name,
      gender: Gender.male,
      privilege: Role.elder,
      qualifications: const [],
      originCongregation: '',
      active: true,
      notes: '',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
