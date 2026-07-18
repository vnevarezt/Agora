// The 4b founder flow end-to-end, minus the network: device A sets up sync
// keys, enables cloud on a congregation (mint CCK + create space), pushes the
// seeded outbox; device B (SAME account, new device) unlocks with the
// passphrase, recovers the CCK from the member doc and pulls. Wires the real
// key services + engine over the fakes that stand in for Firestore.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/crypto/passphrase_envelope.dart';
import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/data/sync/cck_service.dart';
import 'package:jw_program/data/sync/content_crypto.dart';
import 'package:jw_program/data/sync/sync_engine.dart';
import 'package:jw_program/data/sync/sync_seeder.dart';
import 'package:jw_program/data/sync/hlc.dart';
import 'package:jw_program/data/sync/sync_scribe.dart';
import 'package:jw_program/data/sync/user_key_service.dart';
import 'package:jw_program/models/person.dart';
import 'package:jw_program/state/dashboard_provider.dart';
import 'package:jw_program/state/db_provider.dart';
import 'package:jw_program/state/people_provider.dart';

import '../helpers/fake_key_docs.dart';
import '../helpers/in_memory_transport.dart';
import '../helpers/map_key_store.dart';

const _fast = KdfParams(memoryKib: 64, iterations: 1, parallelism: 1);

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
    userKeys = UserKeyService(store, docs,
        uid: uid, envelope: const PassphraseEnvelope(params: _fast));
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

    await a.userKeys.create('mi-frase-larga');
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
    await b.userKeys.unlock('mi-frase-larga');

    final page = await b.engine.pullOnce(cong.id);
    expect(page.applied, 2);
    final bPeople = await b.container.read(peopleRepositoryProvider).all();
    expect(bPeople.single.displayName, 'Ana');
  });

  test('a device without the passphrase cannot pull (keyring null)', () async {
    final transport = InMemoryTransport();
    final docs = FakeKeyDocs();
    final a = CloudDevice('devA', transport, docs, uid: 'u1');
    addTearDown(a.dispose);

    final cong = await a.container
        .read(congregationsRepositoryProvider)
        .create(name: 'Sur', number: '1');
    await a.userKeys.create('frase');
    await a.cck.createCongregationSpace(cong.id);
    await a.seeder.seedCongregation(cong.id);
    await a.engine.pushOnce();

    // Device B never unlocks: keyringFor → null, pull applies nothing.
    final b = CloudDevice('devB', transport, docs, uid: 'u1');
    addTearDown(b.dispose);
    final page = await b.engine.pullOnce(cong.id);
    expect(page.fetched, 0);
    expect(page.applied, 0);
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
