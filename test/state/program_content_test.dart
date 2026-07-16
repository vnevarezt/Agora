// ProgramContentService: fills missing snapshots by resolving week labels
// through the notebook catalog, skips uncached notebooks, and is idempotent.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/data/mwb_cache.dart';
import 'package:jw_program/data/mwb_repository.dart';
import 'package:jw_program/models/notebook.dart';
import 'package:jw_program/models/week.dart';
import 'package:jw_program/state/dashboard_provider.dart';
import 'package:jw_program/state/db_provider.dart';
import 'package:jw_program/state/program_content.dart';
import 'package:jw_program/state/weeks_provider.dart';

/// Serves canned weeks per issue and counts the parses (must be 1 per
/// issue thanks to the service's memo, and 0 when nothing is missing).
class _FakeMwbRepository extends MwbRepository {
  _FakeMwbRepository(this.byIssue) : super(MwbCache());

  final Map<String, List<Week>> byIssue;
  int parseCalls = 0;

  @override
  Future<List<Week>> weeks(String issue, {String lang = 'S'}) async {
    parseCalls++;
    return byIssue[issue] ?? const [];
  }
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late _FakeMwbRepository fake;

  Week week(String date) => Week(date: date, parts: [
        const Part(
            section: Section.treasures, number: 1, title: 'Tesoros', minutes: 10),
      ]);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fake = _FakeMwbRepository({
      '202607': [week('7-13 DE JULIO'), week('14-20 DE JULIO')],
    });
    container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      repositoryProvider.overrideWithValue(fake),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);
    container.read(notebooksProvider.notifier).setFrom([
      const Notebook(
          id: '202607',
          label: 'Julio 2026',
          weeks: ['7-13 DE JULIO', '14-20 DE JULIO']),
    ]);
  });

  test('fills missing snapshots, one parse per issue, then idempotent',
      () async {
    final projectId = await container.read(projectsRepositoryProvider).create(
      name: 'P',
      congregationId: '',
      weeks: ['7-13 DE JULIO', '14-20 DE JULIO'],
    );
    final service = container.read(programContentServiceProvider);

    await service.ensureProjectContent(projectId);

    final programs =
        await container.read(programsRepositoryProvider).byProject(projectId);
    expect(programs.map((p) => p.contentJson), everyElement(isNotNull));
    expect(fake.parseCalls, 1, reason: 'both weeks share one issue');

    await service.ensureProjectContent(projectId);
    expect(fake.parseCalls, 1, reason: 'nothing missing → no re-parse');
  });

  test('weeks from uncached notebooks stay skeleton (retried later)',
      () async {
    final projectId = await container.read(projectsRepositoryProvider).create(
      name: 'P',
      congregationId: '',
      weeks: ['7-13 DE JULIO', 'SEMANA DESCONOCIDA'],
    );

    await container
        .read(programContentServiceProvider)
        .ensureProjectContent(projectId);

    final programs =
        await container.read(programsRepositoryProvider).byProject(projectId);
    expect(programs.first.contentJson, isNotNull);
    expect(programs.last.contentJson, isNull);
  });
}
