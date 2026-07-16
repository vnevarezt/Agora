// Phase-3 scaffolding: every repository mutation stamps the row's hlc and
// enqueues an outbox entry in the same transaction.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/data/sync/sync_scribe.dart';
import 'package:jw_program/models/hall.dart';
import 'package:jw_program/models/person.dart';
import 'package:jw_program/models/week_type.dart';
import 'package:jw_program/state/dashboard_provider.dart';
import 'package:jw_program/state/db_provider.dart';
import 'package:jw_program/state/people_provider.dart';
import 'package:jw_program/state/program_content.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);
  });

  Future<List<OutboxEntry>> outbox() => db.select(db.outbox).get();

  Person person(String id) => Person(
        id: id,
        congregationId: '',
        firstName: '',
        lastName: '',
        displayName: 'Ana',
        gender: Gender.female,
        privilege: Role.publisher,
        qualifications: const [],
        originCongregation: '',
        active: true,
        notes: '',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  test('mutations enqueue entries with monotonic hlc mirrored on the rows',
      () async {
    final people = container.read(peopleRepositoryProvider);
    await people.save(person('p1')); // + default congregation created

    var entries = await outbox();
    expect(
      {for (final e in entries) e.entity},
      {SyncEntity.congregation.name, SyncEntity.person.name},
    );
    final personRow = (await people.all()).single;
    final personEntry =
        entries.singleWhere((e) => e.entity == SyncEntity.person.name);
    expect(personRow.hlc, personEntry.hlc,
        reason: 'row stamp mirrors the outbox stamp');

    await people.delete('p1');
    entries = await outbox();
    expect(entries, hasLength(3));
    final stamps = [for (final e in entries) e.hlc];
    final sorted = [...stamps]..sort();
    expect(stamps, sorted, reason: 'outbox order follows hlc order');
    expect(stamps.toSet(), hasLength(3), reason: 'stamps are unique');
  });

  test('project lifecycle enqueues project + cascaded programs', () async {
    final projects = container.read(projectsRepositoryProvider);
    final id = await projects.create(
        name: 'P', congregationId: '', weeks: ['W1', 'W2']);
    // congregation (default) + project + 2 programs
    expect(await outbox(), hasLength(4));

    await projects.delete(id);
    // + project tombstone + 2 program tombstones
    final entries = await outbox();
    expect(entries, hasLength(7));
    expect(
      entries.where((e) => e.entity == SyncEntity.program.name).length,
      4,
    );
  });

  test('slot writes enqueue one entry per touched assignment row', () async {
    final projects = container.read(projectsRepositoryProvider);
    final programs = container.read(programsRepositoryProvider);
    await projects.create(name: 'P', congregationId: '', weeks: ['W1']);
    final program =
        (await projects.watchAll().first).single.programs.single;

    await programs.saveSlotNames(
        programId: program.id,
        slotKey: 'se1',
        hall: Hall.main,
        names: ['Ana', 'Luis']);
    await programs.saveSlotNames(
        programId: program.id,
        slotKey: 'se1',
        hall: Hall.main,
        names: ['Ana', '']); // one untouched, one tombstoned

    final entries = await outbox();
    expect(
      entries.where((e) => e.entity == SyncEntity.assignment.name).length,
      3, // two inserts + one tombstone; the unchanged name enqueues nothing
    );

    await programs.setWeekType(program.id, WeekType.circuitOverseerVisit);
    final program2 =
        (await projects.watchAll().first).single.programs.single;
    final last = (await outbox()).last;
    expect(last.entity, SyncEntity.program.name);
    expect(program2.hlc, last.hlc);
  });
}
