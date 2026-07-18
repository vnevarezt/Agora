// Two-device sync (phase 4a): push/pull over the in-memory transport with
// real repositories on both ends — the full loop a future Firestore
// deployment will run, minus the network.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/data/sync/content_crypto.dart';
import 'package:jw_program/data/sync/sync_engine.dart';
import 'package:jw_program/models/hall.dart';
import 'package:jw_program/models/person.dart';
import 'package:jw_program/state/dashboard_provider.dart';
import 'package:jw_program/state/db_provider.dart';
import 'package:jw_program/state/people_provider.dart';
import 'package:jw_program/state/program_content.dart';

import '../helpers/in_memory_transport.dart';

class Device {
  Device(this.name, InMemoryTransport transport,
      Map<String, CongregationKeyring> keyrings) {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
    ]);
    engine = SyncEngine(
      db,
      transport,
      ContentCrypto(),
      deviceId: name,
      keyringFor: (cid) async => keyrings[cid],
    );
  }

  final String name;
  late final AppDatabase db;
  late final ProviderContainer container;
  late final SyncEngine engine;

  Future<int> outboxCount() async =>
      (await db.select(db.outbox).get()).length;

  void dispose() {
    container.dispose();
    db.close();
  }
}

void main() {
  late InMemoryTransport transport;
  late Map<String, CongregationKeyring> keyrings;
  late Device a;
  late Device b;

  setUp(() {
    transport = InMemoryTransport();
    keyrings = {};
    a = Device('devA', transport, keyrings);
    b = Device('devB', transport, keyrings);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
  });

  Person person(String id, String name, String congregationId) => Person(
        id: id,
        congregationId: congregationId,
        firstName: '',
        lastName: '',
        displayName: name,
        gender: Gender.male,
        privilege: Role.elder,
        qualifications: const ['read'],
        originCongregation: '',
        active: true,
        notes: 'nota',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  test('full loop: push, pull, echo suppression, LWW conflict, delete',
      () async {
    // --- Device A creates real data through the repositories.
    final cong = await a.container
        .read(congregationsRepositoryProvider)
        .create(name: 'Norte', number: '7');
    await a.container
        .read(peopleRepositoryProvider)
        .save(person('p1', 'Ana', cong.id));
    await a.container
        .read(projectsRepositoryProvider)
        .create(name: 'Julio', congregationId: cong.id, weeks: ['W1']);
    final program = (await a.container
            .read(projectsRepositoryProvider)
            .watchAll()
            .first)
        .single
        .programs
        .single;
    await a.container.read(programsRepositoryProvider).saveSlotNames(
        programId: program.id,
        slotKey: 'te0',
        hall: Hall.main,
        names: ['Ana']);

    // --- Without a keyring the outbox stays queued (not syncable yet).
    expect(await a.engine.pushOnce(), 0);
    expect(await a.outboxCount(), greaterThan(0));

    // --- Enable sync for the congregation and push.
    keyrings[cong.id] = CongregationKeyring({1: CongregationKeyring.newKey()});
    final pushed = await a.engine.pushOnce();
    expect(pushed, 5); // congregation + person + project + program + assignment
    expect(await a.outboxCount(), 0);

    // The server never sees content: only base64 blobs + metadata.
    for (final doc in transport.docs[cong.id]!.values) {
      expect(doc.blob.contains('Ana'), false);
      expect(doc.blob.contains('Norte'), false);
    }
    // programTypeId IS clear metadata (rules gate edit:<type> with it), but
    // only on program/assignment docs.
    for (final doc in transport.docs[cong.id]!.values) {
      final typed = doc.entity == 'program' || doc.entity == 'assignment';
      expect(doc.programTypeId, typed ? 'mwb-s140' : isNull);
    }

    // --- Device B pulls everything.
    expect((await b.engine.pullOnce(cong.id)).applied, 5);
    final bPerson =
        (await b.container.read(peopleRepositoryProvider).all()).single;
    expect(bPerson.displayName, 'Ana');
    expect(bPerson.qualifications, ['read']);
    final bData = (await b.container
            .read(projectsRepositoryProvider)
            .watchAll()
            .first)
        .single;
    expect(bData.project.name, 'Julio');
    expect(bData.programs.single.date, 'W1');
    final bAssignments = await b.container
        .read(programsRepositoryProvider)
        .assignmentsByPrograms([bData.programs.single.id]);
    expect(bAssignments.single.displayName, 'Ana');

    // Pulled rows must NOT re-enqueue (no echo storms).
    expect(await b.outboxCount(), 0);

    // --- Echo suppression: A pulls its own writes back, applies nothing.
    expect((await a.engine.pullOnce(cong.id)).applied, 0);

    // --- LWW conflict: B renames first, A renames later → A wins.
    await b.container
        .read(peopleRepositoryProvider)
        .save(bPerson.copyWith(displayName: 'Eva'));
    await b.engine.pushOnce();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await a.container
        .read(peopleRepositoryProvider)
        .save(person('p1', 'Zoe', cong.id));
    await a.engine.pushOnce();

    await b.engine.pullOnce(cong.id);
    expect(
      (await b.container.read(peopleRepositoryProvider).all())
          .single
          .displayName,
      'Zoe',
    );
    // A pulls B's older doc state: its newer local row must win.
    await a.engine.pullOnce(cong.id);
    expect(
      (await a.container.read(peopleRepositoryProvider).all())
          .single
          .displayName,
      'Zoe',
    );

    // --- Tombstones replicate.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await a.container.read(peopleRepositoryProvider).delete('p1');
    await a.engine.pushOnce();
    await b.engine.pullOnce(cong.id);
    expect(await b.container.read(peopleRepositoryProvider).all(), isEmpty);

    // --- Cursors: a fresh pull with nothing new fetches nothing.
    final noop = await b.engine.pullOnce(cong.id);
    expect(noop.fetched, 0);
    expect(noop.applied, 0);
  });

  test('coalescing: many edits to one row push one doc', () async {
    final cong = await a.container
        .read(congregationsRepositoryProvider)
        .create(name: 'Sur', number: '1');
    keyrings[cong.id] = CongregationKeyring({1: CongregationKeyring.newKey()});
    final repo = a.container.read(peopleRepositoryProvider);
    await repo.save(person('p9', 'V1', cong.id));
    await repo.save(person('p9', 'V2', cong.id));
    await repo.save(person('p9', 'V3', cong.id));

    final pushed = await a.engine.pushOnce();
    expect(pushed, 2); // congregation + ONE person doc
    expect((await b.engine.pullOnce(cong.id)).applied, 2);
    expect(
      (await b.container.read(peopleRepositoryProvider).all())
          .single
          .displayName,
      'V3',
    );
  });
}
