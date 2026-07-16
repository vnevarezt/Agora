import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../models/program_type_ids.dart';
import '../db/app_database.dart';
import 'congregations_repository.dart';

/// A project with its alive skeleton programs (phase 1: one row per picked
/// week, slots/assignments arrive in phase 2).
typedef ProjectData = ({ProjectRecord project, List<ProgramRecord> programs});

/// Domain API over projects + their programs. THE write path for both:
/// later phases stamp HLC + outbox here (docs/DATA_ARCHITECTURE.md §3).
class ProjectsRepository {
  ProjectsRepository(this._db, this._congregations);

  final AppDatabase _db;
  final CongregationsRepository _congregations;

  /// Newest project first (the old controller prepended new ones).
  Stream<List<ProjectData>> watchAll() {
    final query = _db.select(_db.projects).join([
      leftOuterJoin(
        _db.programs,
        _db.programs.projectId.equalsExp(_db.projects.id) &
            _db.programs.deletedAt.isNull(),
      ),
    ])
      ..where(_db.projects.deletedAt.isNull())
      ..orderBy([
        OrderingTerm.desc(_db.projects.createdAt),
        OrderingTerm.asc(_db.programs.sortIndex),
      ]);

    return query.watch().map((rows) {
      // Group join rows by project, preserving the query order.
      final byId = <String, (ProjectRecord, List<ProgramRecord>)>{};
      for (final row in rows) {
        final project = row.readTable(_db.projects);
        final entry = byId.putIfAbsent(project.id, () => (project, []));
        final program = row.readTableOrNull(_db.programs);
        if (program != null) entry.$2.add(program);
      }
      return [
        for (final (project, programs) in byId.values)
          (project: project, programs: programs),
      ];
    });
  }

  /// Returns the new project id (callers chain the content snapshot).
  Future<String> create({
    required String name,
    required String congregationId,
    required List<String> weeks,
  }) async {
    final congId = congregationId.isEmpty
        ? await _congregations.ensureDefault()
        : congregationId;
    final now = DateTime.now().toUtc();
    final projectId = const Uuid().v4();
    await _db.transaction(() async {
      await _db.into(_db.projects).insert(ProjectsCompanion.insert(
            id: projectId,
            congregationId: congId,
            name: name,
            createdAt: now,
            updatedAt: now,
          ));
      await _insertPrograms(projectId, weeks, now);
    });
    return projectId;
  }

  /// Week diffing keeps the surviving programs' ids stable — phase 2 hangs
  /// slots/assignments off them, so re-editing a project must not recreate
  /// its untouched weeks.
  Future<void> update(
    String id, {
    required String name,
    required String congregationId,
    required List<String> weeks,
  }) async {
    final congId = congregationId.isEmpty
        ? await _congregations.ensureDefault()
        : congregationId;
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
        ProjectsCompanion(
          name: Value(name),
          congregationId: Value(congId),
          updatedAt: Value(now),
        ),
      );

      final existing = await (_db.select(_db.programs)
            ..where((t) => t.projectId.equals(id) & t.deletedAt.isNull()))
          .get();
      final wanted = weeks.toSet();
      final removed = [for (final p in existing) if (!wanted.contains(p.date)) p.id];
      if (removed.isNotEmpty) {
        await (_db.update(_db.programs)..where((t) => t.id.isIn(removed)))
            .write(ProgramsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ));
      }
      // Survivors keep their id (phase 2 hangs assignments off it) but get
      // their position reassigned; new weeks are inserted at theirs.
      final byDate = {for (final p in existing) p.date: p};
      for (var i = 0; i < weeks.length; i++) {
        final current = byDate[weeks[i]];
        if (current == null) {
          await _insertProgram(id, weeks[i], i, now);
        } else if (current.sortIndex != i) {
          await (_db.update(_db.programs)
                ..where((t) => t.id.equals(current.id)))
              .write(ProgramsCompanion(sortIndex: Value(i)));
        }
      }
    });
  }

  /// Soft delete, cascading to the project's alive programs.
  Future<void> delete(String id) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
        ProjectsCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      await (_db.update(_db.programs)
            ..where((t) => t.projectId.equals(id) & t.deletedAt.isNull()))
          .write(ProgramsCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
      ));
    });
  }

  /// Stamps the export (drives the derived `exported` status).
  Future<void> markExported(String id) async {
    final now = DateTime.now().toUtc();
    await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
      ProjectsCompanion(exportedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<void> _insertPrograms(
      String projectId, List<String> weeks, DateTime now) async {
    for (var i = 0; i < weeks.length; i++) {
      await _insertProgram(projectId, weeks[i], i, now);
    }
  }

  Future<void> _insertProgram(
      String projectId, String week, int sortIndex, DateTime now) {
    return _db.into(_db.programs).insert(ProgramsCompanion.insert(
          id: const Uuid().v4(),
          projectId: projectId,
          programTypeId: ProgramTypeIds.mwbS140,
          date: week,
          sortIndex: Value(sortIndex),
          createdAt: now,
          updatedAt: now,
        ));
  }
}
