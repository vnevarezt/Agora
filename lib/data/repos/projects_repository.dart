import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../models/hall.dart';
import '../../models/notebook.dart';
import '../../models/program_type_ids.dart';
import '../db/app_database.dart';
import '../sync/sync_scribe.dart';
import 'congregations_repository.dart';

/// A project with its alive skeleton programs (phase 1: one row per picked
/// week, slots/assignments arrive in phase 2).
typedef ProjectData = ({ProjectRecord project, List<ProgramRecord> programs});

/// Domain API over projects + their programs. THE write path for both:
/// it stamps HLC + outbox (docs/PHASE3_SYNC_SCAFFOLDING.md).
class ProjectsRepository {
  ProjectsRepository(this._db, this._congregations, this._scribe);

  final AppDatabase _db;
  final CongregationsRepository _congregations;
  final SyncScribe _scribe;

  /// Congregation a project belongs to, or null if it is gone. A direct lookup
  /// rather than a read of `projectsProvider`, which derives progress for every
  /// project (assignment counts, week snapshots) — far too much to pull in just
  /// to answer which workbook language a project uses.
  Future<String?> congregationIdOf(String projectId) async {
    final row =
        await (_db.select(_db.projects)
              ..where((p) => p.id.equals(projectId))
              ..limit(1))
            .getSingleOrNull();
    return row?.congregationId;
  }

  /// Alive project ids of one congregation, oldest first. Same reasoning as
  /// [congregationIdOf]: the reconciler runs in the background and must not
  /// subscribe to the dashboard's derived project stream just to learn which
  /// projects a language change touches.
  Future<List<String>> idsByCongregation(String congregationId) async {
    final rows =
        await (_db.selectOnly(_db.projects)
              ..addColumns([_db.projects.id])
              ..where(
                _db.projects.congregationId.equals(congregationId) &
                    _db.projects.deletedAt.isNull(),
              )
              ..orderBy([OrderingTerm.asc(_db.projects.createdAt)]))
            .get();
    return [for (final r in rows) r.read(_db.projects.id)!];
  }

  /// Newest project first (the old controller prepended new ones).
  Stream<List<ProjectData>> watchAll() {
    final query =
        _db.select(_db.projects).join([
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
    required List<WeekRef> weeks,
  }) async {
    final congId = congregationId.isEmpty
        ? await _congregations.ensureDefault()
        : congregationId;
    final now = DateTime.now().toUtc();
    final hlc = await _scribe.nextHlc();
    final projectId = const Uuid().v4();
    await _db.transaction(() async {
      await _db
          .into(_db.projects)
          .insert(
            ProjectsCompanion.insert(
              id: projectId,
              congregationId: congId,
              name: name,
              createdAt: now,
              updatedAt: now,
              hlc: Value(hlc),
            ),
          );
      await _scribe.enqueue(SyncEntity.project, projectId, hlc);
      await _insertPrograms(projectId, weeks, now, hlc);
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
    required List<WeekRef> weeks,
  }) async {
    final congId = congregationId.isEmpty
        ? await _congregations.ensureDefault()
        : congregationId;
    final now = DateTime.now().toUtc();
    final hlc = await _scribe.nextHlc();
    await _db.transaction(() async {
      await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
        ProjectsCompanion(
          name: Value(name),
          congregationId: Value(congId),
          updatedAt: Value(now),
          hlc: Value(hlc),
        ),
      );
      await _scribe.enqueue(SyncEntity.project, id, hlc);

      final existing = await (_db.select(
        _db.programs,
      )..where((t) => t.projectId.equals(id) & t.deletedAt.isNull())).get();

      // Match on the language-free identity first and fall back to the printed
      // label. Both halves are load-bearing: matching only on the label loses
      // every program the moment the congregation changes language (the modal
      // offers English headings while the rows hold Spanish ones, so all of
      // them look removed and their assignments go with them), while matching
      // only on weekStart loses the rows written before v6, which have none.
      final claimed = <String>{};
      ProgramRecord? matchOf(WeekRef wanted) {
        for (final p in existing) {
          if (claimed.contains(p.id)) continue;
          final start = p.weekStart;
          if (start != null && start.isNotEmpty && start == wanted.start) {
            claimed.add(p.id);
            return p;
          }
        }
        for (final p in existing) {
          if (claimed.contains(p.id)) continue;
          if (p.date == wanted.label) {
            claimed.add(p.id);
            return p;
          }
        }
        return null;
      }

      final matched = {for (final w in weeks) w: matchOf(w)};
      final kept = {
        for (final p in matched.values)
          if (p != null) p.id,
      };
      final removed = [
        for (final p in existing)
          if (!kept.contains(p.id)) p.id,
      ];
      if (removed.isNotEmpty) {
        await (_db.update(
          _db.programs,
        )..where((t) => t.id.isIn(removed))).write(
          ProgramsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
            hlc: Value(hlc),
          ),
        );
        for (final programId in removed) {
          await _scribe.enqueue(SyncEntity.program, programId, hlc);
        }
      }
      // Survivors keep their id (phase 2 hangs assignments off it) but get
      // their position reassigned; new weeks are inserted at theirs.
      for (var i = 0; i < weeks.length; i++) {
        final current = matched[weeks[i]];
        if (current == null) {
          await _insertProgram(id, weeks[i], i, now, hlc);
          continue;
        }
        // A survivor matched by label alone has no identity yet: record it, so
        // the next edit matches on the identity and this repair happens once.
        final needsIdentity =
            weeks[i].start.isNotEmpty &&
            (current.weekStart == null || current.weekStart!.isEmpty);
        if (current.sortIndex != i || needsIdentity) {
          await (_db.update(
            _db.programs,
          )..where((t) => t.id.equals(current.id))).write(
            ProgramsCompanion(
              sortIndex: Value(i),
              weekStart: needsIdentity
                  ? Value(weeks[i].start)
                  : const Value.absent(),
              hlc: Value(hlc),
            ),
          );
          await _scribe.enqueue(SyncEntity.program, current.id, hlc);
        }
      }
    });
  }

  /// Soft delete, cascading to the project's alive programs.
  Future<void> delete(String id) async {
    final now = DateTime.now().toUtc();
    final hlc = await _scribe.nextHlc();
    await _db.transaction(() async {
      final rows =
          await (_db.selectOnly(_db.programs)
                ..addColumns([_db.programs.id])
                ..where(
                  _db.programs.projectId.equals(id) &
                      _db.programs.deletedAt.isNull(),
                ))
              .get();
      final programIds = [for (final r in rows) r.read(_db.programs.id)!];

      await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
        ProjectsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          hlc: Value(hlc),
        ),
      );
      await _scribe.enqueue(SyncEntity.project, id, hlc);
      await (_db.update(
        _db.programs,
      )..where((t) => t.projectId.equals(id) & t.deletedAt.isNull())).write(
        ProgramsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          hlc: Value(hlc),
        ),
      );
      for (final programId in programIds) {
        await _scribe.enqueue(SyncEntity.program, programId, hlc);
      }
    });
  }

  /// Alive assignment counts per (programId, hall) — feeds the dashboard
  /// cards' real progress.
  ///
  /// Aggregated in SQL, not in Dart: the previous version selected every alive
  /// assignment row and grouped them here, so each saved name re-emitted the
  /// whole table and re-derived every project card. `selectOnly(..groupBy)` is
  /// still avoided — that is the builder that starved the event loop with
  /// endless re-emissions (2026-07: timers stopped firing in tests once the
  /// stream became active); customSelect does not share that path.
  Stream<Map<(String, Hall), int>> watchAssignmentCounts() {
    return _db
        .customSelect(
          'SELECT program_id, hall, COUNT(*) AS c FROM assignments '
          'WHERE deleted_at IS NULL GROUP BY program_id, hall',
          readsFrom: {_db.assignmentRows},
        )
        .watch()
        .map(
          (rows) => {
            for (final row in rows)
              (
                row.read<String>('program_id'),
                Hall.values.byName(row.read<String>('hall')),
              ): row.read<int>(
                'c',
              ),
          },
        );
  }

  /// Stamps the export (drives the derived `exported` status).
  Future<void> markExported(String id) async {
    final now = DateTime.now().toUtc();
    final hlc = await _scribe.nextHlc();
    await _db.transaction(() async {
      await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
        ProjectsCompanion(
          exportedAt: Value(now),
          updatedAt: Value(now),
          hlc: Value(hlc),
        ),
      );
      await _scribe.enqueue(SyncEntity.project, id, hlc);
    });
  }

  Future<void> _insertPrograms(
    String projectId,
    List<WeekRef> weeks,
    DateTime now,
    String hlc,
  ) async {
    for (var i = 0; i < weeks.length; i++) {
      await _insertProgram(projectId, weeks[i], i, now, hlc);
    }
  }

  Future<void> _insertProgram(
    String projectId,
    WeekRef week,
    int sortIndex,
    DateTime now,
    String hlc,
  ) async {
    final programId = const Uuid().v4();
    await _db
        .into(_db.programs)
        .insert(
          ProgramsCompanion.insert(
            id: programId,
            projectId: projectId,
            programTypeId: ProgramTypeIds.mwbS140,
            date: week.label,
            weekStart: week.start.isEmpty
                ? const Value.absent()
                : Value(week.start),
            sortIndex: Value(sortIndex),
            createdAt: now,
            updatedAt: now,
            hlc: Value(hlc),
          ),
        );
    await _scribe.enqueue(SyncEntity.program, programId, hlc);
  }
}
