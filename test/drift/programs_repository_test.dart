// ProgramsRepository on an in-memory DB: slot-name writes (insert, update,
// tombstone), content snapshot bookkeeping, per-project config and ordering.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/data/repos/programs_repository.dart';
import 'package:jw_program/models/hall.dart';
import 'package:jw_program/models/week.dart';
import 'package:jw_program/models/week_type.dart';
import 'package:jw_program/state/dashboard_provider.dart';
import 'package:jw_program/state/db_provider.dart';
import 'package:jw_program/state/program_content.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late String projectId;
  late ProgramsRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);
    projectId = await container.read(projectsRepositoryProvider).create(
      name: 'P',
      congregationId: '',
      weeks: ['7-13 DE JULIO', '14-20 DE JULIO'],
    );
    repo = container.read(programsRepositoryProvider);
  });

  test('byProject follows sortIndex, not the label alphabet', () async {
    final programs = await repo.byProject(projectId);
    // '14-20' sorts before '7-13' alphabetically; sortIndex must win.
    expect(programs.map((p) => p.date), ['7-13 DE JULIO', '14-20 DE JULIO']);
  });

  test('saveSlotNames: insert, update, clear and shrink', () async {
    final program = (await repo.byProject(projectId)).first;

    await repo.saveSlotNames(
        programId: program.id,
        slotKey: 'se1',
        hall: Hall.main,
        names: ['Ana', 'Luis']);
    var rows = await repo.assignmentsByPrograms([program.id]);
    expect({for (final r in rows) r.position: r.displayName},
        {0: 'Ana', 1: 'Luis'});

    // Update one position, clear the other.
    await repo.saveSlotNames(
        programId: program.id,
        slotKey: 'se1',
        hall: Hall.main,
        names: ['Eva', '']);
    rows = await repo.assignmentsByPrograms([program.id]);
    expect({for (final r in rows) r.position: r.displayName}, {0: 'Eva'});

    // A different hall is an independent list.
    await repo.saveSlotNames(
        programId: program.id,
        slotKey: 'se1',
        hall: Hall.aux,
        names: ['Sara']);
    rows = await repo.assignmentsByPrograms([program.id]);
    expect(rows, hasLength(2));

    // Shrinking the list tombstones positions beyond it.
    await repo.saveSlotNames(
        programId: program.id, slotKey: 'se1', hall: Hall.main, names: []);
    rows = await repo.assignmentsByPrograms([program.id]);
    expect(rows.single.hall, Hall.aux);

    // Tombstones stay in the table for future sync.
    final raw = await db
        .customSelect('SELECT COUNT(*) AS n FROM assignments').getSingle();
    expect(raw.read<int>('n'), 3);
  });

  test('setContent stores the snapshot without touching updatedAt',
      () async {
    final before = (await repo.byProject(projectId)).first;
    final week = Week(date: '7-13 DE JULIO', reading: 'PROV. 1', parts: [
      const Part(
          section: Section.ministry,
          number: 3,
          title: 'Empiece conversaciones',
          minutes: 3),
    ]);

    await repo.setContent(before.id, week);

    final after = (await repo.byProject(projectId)).first;
    expect(after.contentJson, isNotNull);
    expect(after.updatedAt, before.updatedAt,
        reason: 'snapshotting is bookkeeping, not an edit');
  });

  test('setProjectConfig writes every program; setWeekType only one',
      () async {
    await repo.setProjectConfig(projectId, auxRoom: true, startTime: '19:30');
    final programs = await repo.byProject(projectId);
    expect(programs.map((p) => p.auxRoom).toSet(), {true});
    expect(programs.map((p) => p.startTime).toSet(), {'19:30'});
    expect(programs.map((p) => p.durationMinutes).toSet(), {null});

    await repo.setWeekType(programs.first.id, WeekType.circuitOverseerVisit);
    final again = await repo.byProject(projectId);
    expect(again.first.weekType, WeekType.circuitOverseerVisit);
    expect(again.last.weekType, WeekType.normal);
  });
}
