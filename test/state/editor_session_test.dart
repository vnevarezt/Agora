// Editor session (phase 2): hydration maps DB rows into the form, and the
// form's write-through persists edits back — the full roundtrip a restart
// must survive.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/models/congregation_settings.dart';
import 'package:jw_program/models/hall.dart';
import 'package:jw_program/models/project.dart';
import 'package:jw_program/models/week_type.dart';
import 'package:jw_program/state/dashboard_provider.dart';
import 'package:jw_program/state/db_provider.dart';
import 'package:jw_program/state/editor_session.dart';
import 'package:jw_program/state/program_content.dart';
import 'package:jw_program/state/program_form.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late String projectId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);

    final cong = await container.read(congregationsRepositoryProvider).create(
          name: 'Norte',
          number: '7',
          settings: const CongregationSettings(
              midweekTime: '19:30', auxRoom: true),
        );
    projectId = await container.read(projectsRepositoryProvider).create(
      name: 'Julio',
      congregationId: cong.id,
      weeks: ['7-13 DE JULIO', '14-20 DE JULIO'],
    );
    // Riverpod 3 pauses unlistened providers: keep the streams active for
    // the whole test (the app's widgets do this by watching them).
    container.listen(congregationsStreamProvider, (_, _) {});
    container.listen(projectsStreamProvider, (_, _) {});
    // Prime the sync congregations list (the dashboard does this in app).
    await container.read(congregationsStreamProvider.future);
  });

  Future<Project> projectCard() async =>
      (await container.read(projectsStreamProvider.future))
          .map((d) => d.project)
          .where((p) => p.id == projectId)
          .map((p) => Project(
                id: p.id,
                name: p.name,
                congregationId: p.congregationId,
                weeks: const [],
                done: 0,
                total: 0,
                status: ProjectStatus.draft,
                editedLabel: '',
                updatedAt: DateTime.utc(2026, 1, 1),
              ))
          .first;

  test('hydration maps stored rows; edits write through and re-hydrate',
      () async {
    final programs =
        await container.read(programsRepositoryProvider).byProject(projectId);

    // Pre-existing data from "a previous session".
    final repo = container.read(programsRepositoryProvider);
    await repo.saveSlotNames(
        programId: programs[0].id,
        slotKey: 'chairman',
        hall: Hall.main,
        names: ['Andrés']);
    await repo.saveSlotNames(
        programId: programs[0].id,
        slotKey: 'se1',
        hall: Hall.main,
        names: ['Ana', 'Luis']);
    await repo.setWeekType(programs[1].id, WeekType.circuitOverseerVisit);
    await repo.setTitleOverrides(programs[1].id, {'vi2': 'Necesidades'});

    await container.read(editorOpenerProvider).open(await projectCard());

    var f = container.read(formProvider);
    expect(f.congregationId, 'Norte');
    expect(f.startTime, '19:30', reason: 'congregation setting is the default');
    expect(f.auxRoom, true);
    expect(f.chairmanByWeek[0], 'Andrés');
    expect(f.mainByWeek[0]!['se1'], ['Ana', 'Luis']);
    expect(f.circuitOverseerByWeek[1], true);
    expect(f.titleOverridesByWeek[1], {'vi2': 'Necesidades'});

    // Edits go through the form and land in the DB.
    final controller = container.read(formProvider.notifier);
    controller.setMainNames('se1', ['Eva', '']);
    controller.setChairman('Marcos');
    controller.selectWeek(1);
    controller.setCircuitOverseer(1, false);
    controller.setAuxRoom(false);
    await pumpEventQueue();

    // A fresh hydration (the "restart") sees the edited values.
    await container.read(editorOpenerProvider).open(await projectCard());
    f = container.read(formProvider);
    expect(f.mainByWeek[0]!['se1'], ['Eva']);
    expect(f.chairmanByWeek[0], 'Marcos');
    expect(f.circuitOverseerByWeek[1], false);
    expect(f.auxRoom, false, reason: 'program override beats the setting');
  });

  test('hydration tolerates gaps: only position 1 of a pair filled',
      () async {
    final programs =
        await container.read(programsRepositoryProvider).byProject(projectId);
    await container.read(programsRepositoryProvider).saveSlotNames(
        programId: programs[0].id,
        slotKey: 'se2',
        hall: Hall.aux,
        names: ['', 'Sara']);

    await container.read(editorOpenerProvider).open(await projectCard());

    final f = container.read(formProvider);
    expect(f.auxByWeek[0]!['se2'], ['', 'Sara']);
  });
}
