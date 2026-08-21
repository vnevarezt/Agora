// ProjectsRepository + CongregationsRepository on an in-memory DB: skeleton
// programs per picked week, id-stable week diffing on update (phase 2 hangs
// slots/assignments off those ids) and the soft-delete cascade.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agora/data/db/app_database.dart';
import 'package:agora/data/repos/congregations_repository.dart';
import 'package:agora/data/repos/projects_repository.dart';
import 'package:agora/models/congregation_settings.dart';
import 'package:agora/models/hall.dart';
import 'package:agora/models/program_type_ids.dart';
import 'package:agora/models/week_type.dart';
import 'package:agora/state/dashboard_provider.dart';
import 'package:agora/state/db_provider.dart';
import 'package:agora/state/program_reconciler.dart';

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

  ProjectsRepository projects() => container.read(projectsRepositoryProvider);
  CongregationsRepository congs() =>
      container.read(congregationsRepositoryProvider);

  Future<List<ProjectData>> snapshot() async =>
      await projects().watchAll().first;

  test('create persists the project plus one skeleton program per week',
      () async {
    final cong = await congs().create(name: 'Norte', number: '101');
    await projects().create(
      name: 'Julio 2026',
      congregationId: cong.id,
      weeks: [(start: '', label: '2026-07-06'), (start: '', label: '2026-07-13')],
    );

    final data = await snapshot();
    expect(data, hasLength(1));
    expect(data.single.project.name, 'Julio 2026');
    expect(data.single.project.congregationId, cong.id);
    final programs = data.single.programs;
    expect(programs.map((p) => p.date).toSet(), {'2026-07-06', '2026-07-13'});
    expect(programs.map((p) => p.programTypeId).toSet(),
        {ProgramTypeIds.mwbS140});
    expect(programs.map((p) => p.weekType).toSet(), {WeekType.normal});
  });

  test('empty congregation id falls back to the default congregation',
      () async {
    await projects().create(
        name: 'Sin congregación', congregationId: '', weeks: [(start: '', label: '2026-07-06')]);
    final data = await snapshot();
    final defaultId = await congs().ensureDefault();
    expect(data.single.project.congregationId, defaultId);
  });

  test('update diffs weeks: kept ids stable, removed tombstoned, new added',
      () async {
    final cong = await congs().create(name: 'Norte', number: '');
    await projects().create(
      name: 'P',
      congregationId: cong.id,
      weeks: [(start: '', label: '2026-07-06'), (start: '', label: '2026-07-13')],
    );
    var data = await snapshot();
    final id = data.single.project.id;
    final keptId = data.single.programs
        .singleWhere((p) => p.date == '2026-07-06')
        .id;

    await projects().update(
      id,
      name: 'P2',
      congregationId: cong.id,
      weeks: [(start: '', label: '2026-07-06'), (start: '', label: '2026-07-20')],
    );

    data = await snapshot();
    final byDate = {for (final p in data.single.programs) p.date: p};
    expect(byDate.keys.toSet(), {'2026-07-06', '2026-07-20'});
    expect(byDate['2026-07-06']!.id, keptId,
        reason: 'surviving weeks must keep their program id');
    expect(data.single.project.name, 'P2');

    // The removed week is tombstoned, not erased.
    final raw = await db
        .customSelect("SELECT deleted_at FROM programs WHERE date = '2026-07-13'")
        .get();
    expect(raw.single.read<String?>('deleted_at'), isNotNull);
  });

  test('delete soft-cascades to the programs', () async {
    await projects()
        .create(name: 'P', congregationId: '', weeks: [(start: '', label: '2026-07-06')]);
    final id = (await snapshot()).single.project.id;

    await projects().delete(id);

    expect(await snapshot(), isEmpty);
    final raw = await db
        .customSelect('SELECT deleted_at FROM programs').get();
    expect(raw.single.read<String?>('deleted_at'), isNotNull);
  });

  test('congregation colors cycle over the palette', () async {
    final a = await congs().create(name: 'A', number: '');
    final b = await congs().create(name: 'B', number: '');
    expect(a.color, congregationPalette[0]);
    expect(b.color, congregationPalette[1]);
  });

  test('congregation update persists name, number and settings', () async {
    final cong = await congs().create(name: 'Norte', number: '1');
    await congs().update(
      cong.id,
      name: 'Sur',
      number: '2',
      settings: const CongregationSettings(auxRoom: true, midweekDay: 0),
    );

    final stored = (await congs().watchAll().first).single;
    expect(stored.name, 'Sur');
    expect(stored.number, '2');
    expect(stored.settings.auxRoom, true);
    expect(stored.settings.midweekDay, 0);
    expect(stored.settings.midweekTime, '19:00'); // untouched default
  });

  test('assignment counts group per program and hall, ignoring tombstones',
      () async {
    await projects()
        .create(name: 'P', congregationId: '', weeks: [(start: '', label: '2026-07-06')]);
    final programId = (await snapshot()).single.programs.single.id;

    await container.read(programsRepositoryProvider).saveSlotNames(
        programId: programId,
        slotKey: 'te0',
        hall: Hall.main,
        names: ['Ana', 'Luis']);
    await container.read(programsRepositoryProvider).saveSlotNames(
        programId: programId,
        slotKey: 'se0',
        hall: Hall.aux,
        names: ['Marta']);

    expect(await projects().watchAssignmentCounts().first, {
      (programId, Hall.main): 2,
      (programId, Hall.aux): 1,
    });

    // Clearing a name tombstones its row; it must leave the count.
    await container.read(programsRepositoryProvider).saveSlotNames(
        programId: programId,
        slotKey: 'te0',
        hall: Hall.main,
        names: ['Ana', '']);

    expect(await projects().watchAssignmentCounts().first, {
      (programId, Hall.main): 1,
      (programId, Hall.aux): 1,
    });
  });

  test('assignment counts start empty', () async {
    expect(await projects().watchAssignmentCounts().first, isEmpty);
  });

  test('re-editing after a language switch keeps the programs and their names',
      () async {
    // The modal offers the NEW language's headings while the rows still hold
    // the old ones. Diffing on the label alone would see every week as removed
    // and every one as new: same weeks on screen, every assignment gone.
    const monday = '2026-06-01';
    final projectId = await projects().create(
      name: 'Junio',
      congregationId: '',
      weeks: const [(start: monday, label: '1-7 DE JUNIO')],
    );
    final before = (await container.read(programsRepositoryProvider).byProject(projectId)).single;
    await container.read(programsRepositoryProvider).saveSlotNames(
        programId: before.id,
        slotKey: 'te0',
        hall: Hall.main,
        names: ['Vicente N.']);

    await projects().update(
      projectId,
      name: 'Junio',
      congregationId: '',
      weeks: const [(start: monday, label: 'JUNE 1-7')],
    );

    final after = (await container.read(programsRepositoryProvider).byProject(projectId)).single;
    expect(after.id, before.id, reason: 'same week, same row');
    final assignments = await container.read(programsRepositoryProvider).assignmentsByPrograms([after.id]);
    expect(assignments.single.displayName, 'Vicente N.');
  });

  test('a row with no identity yet is matched by label and then repaired',
      () async {
    // What a v5 project looks like on its first edit after the upgrade.
    final projectId = await projects().create(
      name: 'Junio',
      congregationId: '',
      weeks: const [(start: '', label: '1-7 DE JUNIO')],
    );
    final before = (await container.read(programsRepositoryProvider).byProject(projectId)).single;
    expect(before.weekStart, isNull);

    await projects().update(
      projectId,
      name: 'Junio',
      congregationId: '',
      weeks: const [(start: '2026-06-01', label: '1-7 DE JUNIO')],
    );

    final after = (await container.read(programsRepositoryProvider).byProject(projectId)).single;
    expect(after.id, before.id, reason: 'the label is what saved it');
    expect(after.weekStart, '2026-06-01',
        reason: 'and the identity is recorded so the next edit is safe');
  });
}
