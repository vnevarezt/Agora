import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repos/programs_repository.dart';
import '../models/notebook.dart';
import '../models/week.dart';
import 'dashboard_provider.dart';
import 'db_provider.dart';
import 'weeks_provider.dart';

final programsRepositoryProvider = Provider<ProgramsRepository>(
    (ref) => ProgramsRepository(ref.watch(dbProvider)));

final programContentServiceProvider =
    Provider<ProgramContentService>(ProgramContentService.new);

/// Fills missing `contentJson` snapshots of a project's programs
/// (docs/PHASE2_PROGRAMS_IN_DB.md): week label → the cached notebook whose
/// catalog contains it → parsed week, persisted onto the program row.
/// Programs whose notebook isn't cached stay skeleton and are retried the
/// next time the project opens. Called fire-and-forget after the project
/// modal saves and when the editor opens a project.
class ProgramContentService {
  ProgramContentService(this._ref);

  final Ref _ref;

  Future<void> ensureProjectContent(String projectId) async {
    final repo = _ref.read(programsRepositoryProvider);
    final missing = [
      for (final p in await repo.byProject(projectId))
        if (p.contentJson == null) p,
    ];
    if (missing.isEmpty) return;

    final notebooks = _ref.read(notebooksProvider);
    final weeksByIssue = <String, List<Week>>{};
    for (final program in missing) {
      Notebook? notebook;
      for (final n in notebooks) {
        if (n.weeks.contains(program.date)) {
          notebook = n;
          break;
        }
      }
      if (notebook == null) continue;

      // Cache-first parse (never the network here: the catalog only lists
      // notebooks that are already on disk).
      final weeks = weeksByIssue[notebook.id] ??=
          await _ref.read(repositoryProvider).weeks(notebook.id);
      for (final week in weeks) {
        if (week.date == program.date) {
          await repo.setContent(program.id, week);
          break;
        }
      }
    }
  }
}
