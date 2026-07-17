// Dashboard card progress (phase 2): totals from the content snapshot via
// the schedule rules, done from the alive assignment rows, complete status
// reachable.
//
// NOTE: this lives in its own file on purpose. The identical test inside
// test/drift/projects_repository_test.dart hangs (timers stop firing after
// the provider streams warm up) while the very same code passes here — the
// interaction is under suspicion between flutter_test's timer handling and
// the riverpod/drift stream graph, not in the production code, which the
// editor-session and repository tests also cover.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/models/hall.dart';
import 'package:jw_program/models/project.dart';
import 'package:jw_program/models/week.dart';
import 'package:jw_program/state/dashboard_provider.dart';
import 'package:jw_program/state/db_provider.dart';
import 'package:jw_program/state/program_content.dart';

void main() {
  test('cards compute real progress from snapshots + assignments', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    final projects = container.read(projectsRepositoryProvider);
    final programs = container.read(programsRepositoryProvider);
    await projects.create(
        name: 'P', congregationId: '', weeks: ['7-13 DE JULIO']);
    final program = (await projects.watchAll().first).single.programs.single;

    // One Bible-reading part → schedule slots: chairman (1) + student (1).
    await programs.setContent(
        program.id,
        Week(date: '7-13 DE JULIO', parts: [
          const Part(
              section: Section.treasures,
              number: 1,
              title: 'Lectura de la Biblia',
              minutes: 4),
        ]));

    // Riverpod 3 pauses unlistened providers: keep the card provider live.
    final sub = container.listen(projectsProvider, (_, _) {});
    addTearDown(sub.close);

    Future<Project> settled() async {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      return container.read(projectsProvider).single;
    }

    var c = await settled();
    expect(c.total, 2);
    expect(c.done, 0);
    expect(c.status, ProjectStatus.draft);

    await programs.saveSlotNames(
        programId: program.id,
        slotKey: 'chairman',
        hall: Hall.main,
        names: ['Andrés']);
    await programs.saveSlotNames(
        programId: program.id,
        slotKey: 'te0',
        hall: Hall.main,
        names: ['Ana']);

    c = await settled();
    expect(c.done, 2);
    expect(c.status, ProjectStatus.complete);
  });
}
