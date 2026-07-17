// ProjectsRepository + CongregationsRepository on an in-memory DB: skeleton
// programs per picked week, id-stable week diffing on update (phase 2 hangs
// slots/assignments off those ids) and the soft-delete cascade.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/data/repos/congregations_repository.dart';
import 'package:jw_program/data/repos/projects_repository.dart';
import 'package:jw_program/models/congregation_settings.dart';
import 'package:jw_program/models/program_type_ids.dart';
import 'package:jw_program/models/week_type.dart';
import 'package:jw_program/state/dashboard_provider.dart';
import 'package:jw_program/state/db_provider.dart';

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
      weeks: ['2026-07-06', '2026-07-13'],
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
        name: 'Sin congregación', congregationId: '', weeks: ['2026-07-06']);
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
      weeks: ['2026-07-06', '2026-07-13'],
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
      weeks: ['2026-07-06', '2026-07-20'],
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
        .create(name: 'P', congregationId: '', weeks: ['2026-07-06']);
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
}
