// Two-device sync (phase 4a): push/pull over the in-memory transport with
// real repositories on both ends — the full loop a future Firestore
// deployment will run, minus the network.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/data/sync/content_crypto.dart';
import 'package:jw_program/data/sync/sync_engine.dart';
import 'package:jw_program/data/sync/sync_transport.dart';
import 'package:jw_program/models/hall.dart';
import 'package:jw_program/models/member_capabilities.dart';
import 'package:jw_program/models/person.dart';
import 'package:jw_program/state/dashboard_provider.dart';
import 'package:jw_program/state/db_provider.dart';
import 'package:jw_program/state/people_provider.dart';
import 'package:jw_program/state/program_content.dart';

import '../helpers/in_memory_transport.dart';

class Device {
  Device(
    this.name,
    InMemoryTransport transport,
    this.keyrings, {
    Map<String, MemberCapabilities>? capabilities,
  }) {
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
      capabilitiesFor: (cid) async => capabilities?[cid],
    );
  }

  final String name;

  /// Shared by reference so a test can hand this device a rotated key
  /// mid-run, the way a keyring refresh does in production.
  final Map<String, CongregationKeyring> keyrings;

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
    // The push announced its activity scopes in the heartbeat: the project
    // (for project/program/assignment), the people directory and the
    // congregation row — with this device as the source.
    final heartbeat = transport.activity[cong.id]!;
    final projectId = (await a.container
            .read(projectsRepositoryProvider)
            .watchAll()
            .first)
        .single
        .project
        .id;
    expect((heartbeat['scopes'] as Map).keys.toSet(),
        {'congregation', 'people', projectId});
    expect(heartbeat['srcDevice'], 'devA');

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

  test('an undecryptable doc is skipped without wedging the batch or cursor',
      () async {
    final cong = await a.container
        .read(congregationsRepositoryProvider)
        .create(name: 'Este', number: '3');
    keyrings[cong.id] = CongregationKeyring({1: CongregationKeyring.newKey()});
    await a.container
        .read(peopleRepositoryProvider)
        .save(person('p1', 'Ana', cong.id));
    await a.engine.pushOnce();

    // Someone with write access injects a blob nobody can open (the cheap
    // denial of service this guards against).
    final poison = transport.docs[cong.id]!.values.first;
    transport.docs[cong.id]!['poison'] = ItemDoc(
      entityId: 'poison',
      entity: 'person',
      hlc: 'zzzzzzzzzzzzzzzzzzz-zzzz-evil',
      srcDevice: 'evil',
      keyVersion: 1,
      blob: 'bm90LWEtcmVhbC1ibG9i',
      serverTs: poison.serverTs,
    );

    final page = await b.engine.pullOnce(cong.id);
    expect(page.undecryptable, 1);
    // The good docs still landed...
    expect(page.applied, greaterThan(0));
    expect(
      (await b.container.read(peopleRepositoryProvider).all()).single.displayName,
      'Ana',
    );
    // ...and the cursor moved on, so the poison can't replay forever.
    expect((await b.engine.pullOnce(cong.id)).fetched, 0);
  });

  // ---- rotation: an unknown key version must never be skipped past --------
  //
  // Skipping it would be permanent data loss: once the cursor is past a doc,
  // nothing ever looks at it again. The DoS fix that made undecryptable docs
  // skippable is deliberately NOT applied to this case.

  /// A congregation on the transport whose newest docs use key version 2,
  /// pushed by a device that holds both versions. Returns the cid, the full
  /// keyring, and a fresh device that only holds v1.
  Future<(String, CongregationKeyring, Device)> rotatedCongregation() async {
    final full = CongregationKeyring(
        {1: CongregationKeyring.newKey(), 2: CongregationKeyring.newKey()});

    final writerKeys = <String, CongregationKeyring>{};
    final writer = Device('devW', transport, writerKeys);
    addTearDown(writer.dispose);
    final cong = await writer.container
        .read(congregationsRepositoryProvider)
        .create(name: 'Oeste', number: '9');

    // First a doc under v1, so there IS readable history behind the gap.
    writerKeys[cong.id] = CongregationKeyring({1: full.keys[1]!});
    await writer.container
        .read(peopleRepositoryProvider)
        .save(person('old', 'Ana', cong.id));
    await writer.engine.pushOnce();

    // Then the rotation, and a doc only v2 opens.
    writerKeys[cong.id] = full;
    await writer.container
        .read(peopleRepositoryProvider)
        .save(person('new', 'Bea', cong.id));
    await writer.engine.pushOnce();

    final laggingKeys = {cong.id: CongregationKeyring({1: full.keys[1]!})};
    final lagging = Device('devL', transport, laggingKeys);
    addTearDown(lagging.dispose);
    return (cong.id, full, lagging);
  }

  Future<int?> missingKeyVersionOf(Device d, String cid) async =>
      (await (d.db.select(d.db.syncState)
                ..where((t) => t.congregationId.equals(cid)))
              .getSingleOrNull())
          ?.missingKeyVersion;

  test('a doc with an unknown key version holds the cursor', () async {
    final (cid, _, lagging) = await rotatedCongregation();

    final page = await lagging.engine.pullOnce(cid);
    expect(page.cursorHeld, isTrue);
    expect(page.unknownKeyVersions, {2});
    // Not counted as corrupt: the blob is fine, we just lack the key.
    expect(page.undecryptable, 0);
    // What we COULD read is applied — the hold is about the cursor only.
    expect(
      (await lagging.container.read(peopleRepositoryProvider).all())
          .single
          .displayName,
      'Ana',
    );
    // The cursor did not move: a second pull sees the very same page.
    final again = await lagging.engine.pullOnce(cid);
    expect(again.fetched, page.fetched);
    expect(again.cursorHeld, isTrue);
    expect(await missingKeyVersionOf(lagging, cid), isNull);
  });

  test('once the rotated key arrives, the held page applies', () async {
    final (cid, full, lagging) = await rotatedCongregation();
    await lagging.engine.pullOnce(cid);

    // A refresh that finds nothing new leaves us exactly where we were.
    final page = await lagging.engine.pullOnce(cid);
    expect(page.cursorHeld, isTrue, reason: 'still lagging');

    // Now the refresh actually lands the rotated key.
    lagging.keyrings[cid] = full;
    final recovered = await lagging.engine.pullOnce(cid);
    expect(recovered.cursorHeld, isFalse);
    expect(
      {
        for (final p in await lagging.container.read(peopleRepositoryProvider).all())
          p.displayName,
      },
      {'Ana', 'Bea'},
    );
    expect((await lagging.engine.pullOnce(cid)).fetched, 0);
  });

  test('a permanently unknown version advances the cursor but is remembered',
      () async {
    final (cid, _, lagging) = await rotatedCongregation();

    // The controller's escape hatch after a refresh didn't help. Without it,
    // a hostile member writing keyVersion: 9999 would freeze the whole
    // congregation — the denial of service we already closed once.
    final page =
        await lagging.engine.pullOnce(cid, acceptUnknownKeyVersions: true);
    expect(page.cursorHeld, isFalse);
    expect(page.unknownKeyVersions, {2});
    expect(await missingKeyVersionOf(lagging, cid), 2);
    // The cursor moved on, so sync is not wedged.
    expect((await lagging.engine.pullOnce(cid)).fetched, 0);
  });

  test('recovering a remembered version rewinds and re-reads what was skipped',
      () async {
    final (cid, full, lagging) = await rotatedCongregation();
    await lagging.engine.pullOnce(cid, acceptUnknownKeyVersions: true);
    expect(
      (await lagging.container.read(peopleRepositoryProvider).all()).length,
      1,
      reason: 'Bea was skipped',
    );

    // The key finally reaches this device (a reconciliation, or an admin
    // repairing the keyring). Rewinding is the ONLY way to get those docs.
    lagging.keyrings[cid] = full;
    final page = await lagging.engine.pullOnce(cid);

    expect(page.applied, 1);
    expect(await missingKeyVersionOf(lagging, cid), isNull);
    expect(
      {
        for (final p in await lagging.container.read(peopleRepositoryProvider).all())
          p.displayName,
      },
      {'Ana', 'Bea'},
    );
    // And it settles: no endless re-pull loop.
    expect((await lagging.engine.pullOnce(cid)).fetched, 0);
  });

  // ---- push: capabilities the server would bounce ------------------------

  test('pushOnce drops docs this member is not allowed to write', () async {
    final caps = <String, MemberCapabilities>{};
    final keys = <String, CongregationKeyring>{};
    final viewer = Device('devV', transport, keys, capabilities: caps);
    addTearDown(viewer.dispose);

    final cong = await viewer.container
        .read(congregationsRepositoryProvider)
        .create(name: 'Centro', number: '2');
    keys[cong.id] = CongregationKeyring({1: CongregationKeyring.newKey()});
    // Allowed to edit people, NOT the congregation settings.
    caps[cong.id] = const MemberCapabilities(people: true);

    await viewer.container
        .read(peopleRepositoryProvider)
        .save(person('p1', 'Ana', cong.id));

    // The whole congregation goes up as ONE batch, so keeping the forbidden
    // `congregation` doc queued would fail the commit and block the person
    // write behind it forever.
    expect(await viewer.engine.pushOnce(), 1);
    expect(await viewer.outboxCount(), 0);
    expect(transport.docs[cong.id]!.keys, ['p1']);
  });

  test('pushOnce does not filter while capabilities are unknown', () async {
    // Null capabilities mean "the membership stream has not loaded", NOT
    // "no rights": dropping outbox rows on a stale read would silently lose
    // the user's edits.
    final keys = <String, CongregationKeyring>{};
    final device = Device('devU', transport, keys);
    addTearDown(device.dispose);

    final cong = await device.container
        .read(congregationsRepositoryProvider)
        .create(name: 'Norte', number: '4');
    keys[cong.id] = CongregationKeyring({1: CongregationKeyring.newKey()});

    expect(await device.engine.pushOnce(), 1);
    expect(transport.docs[cong.id]!.keys, contains(cong.id));
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
