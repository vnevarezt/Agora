import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'sync_scribe.dart';

/// Enqueues a congregation's whole subtree for its first push (4b).
///
/// Rows created before schema v4 (or before the congregation had a cloud
/// space) never got an outbox entry, so enabling sync must seed them. Every
/// row gets a fresh HLC if it lacks one and an outbox entry; the engine's
/// per-entity coalescing means a double-seed is harmless. Runs in one
/// transaction so a crash never half-seeds.
class SyncSeeder {
  SyncSeeder(this._db, this._scribe);

  final AppDatabase _db;
  final SyncScribe _scribe;

  Future<int> seedCongregation(String congregationId) async {
    return _db.transaction(() async {
      var count = 0;

      Future<void> stampAndEnqueue(
        SyncEntity entity,
        String id,
        String? currentHlc,
        Future<void> Function(String hlc) writeHlc,
      ) async {
        final hlc = currentHlc ?? await _scribe.nextHlc();
        if (currentHlc == null) await writeHlc(hlc);
        await _scribe.enqueue(entity, id, hlc);
        count++;
      }

      final congregation = await (_db.select(_db.congregations)
            ..where((t) => t.id.equals(congregationId)))
          .getSingleOrNull();
      if (congregation == null) return 0;
      await stampAndEnqueue(
        SyncEntity.congregation,
        congregation.id,
        congregation.hlc,
        (hlc) => (_db.update(_db.congregations)
              ..where((t) => t.id.equals(congregation.id)))
            .write(CongregationsCompanion(hlc: Value(hlc))),
      );

      final people = await (_db.select(_db.people)
            ..where((t) => t.congregationId.equals(congregationId)))
          .get();
      for (final p in people) {
        await stampAndEnqueue(
          SyncEntity.person,
          p.id,
          p.hlc,
          (hlc) => (_db.update(_db.people)..where((t) => t.id.equals(p.id)))
              .write(PeopleCompanion(hlc: Value(hlc))),
        );
        final absences = await (_db.select(_db.personAbsences)
              ..where((t) => t.personId.equals(p.id)))
            .get();
        for (final a in absences) {
          await stampAndEnqueue(
            SyncEntity.personAbsence,
            a.id,
            a.hlc,
            (hlc) => (_db.update(_db.personAbsences)
                  ..where((t) => t.id.equals(a.id)))
                .write(PersonAbsencesCompanion(hlc: Value(hlc))),
          );
        }
      }

      final projects = await (_db.select(_db.projects)
            ..where((t) => t.congregationId.equals(congregationId)))
          .get();
      for (final proj in projects) {
        await stampAndEnqueue(
          SyncEntity.project,
          proj.id,
          proj.hlc,
          (hlc) => (_db.update(_db.projects)..where((t) => t.id.equals(proj.id)))
              .write(ProjectsCompanion(hlc: Value(hlc))),
        );
        final programs = await (_db.select(_db.programs)
              ..where((t) => t.projectId.equals(proj.id)))
            .get();
        for (final prog in programs) {
          await stampAndEnqueue(
            SyncEntity.program,
            prog.id,
            prog.hlc,
            (hlc) => (_db.update(_db.programs)
                  ..where((t) => t.id.equals(prog.id)))
                .write(ProgramsCompanion(hlc: Value(hlc))),
          );
          final rows = await (_db.select(_db.assignmentRows)
                ..where((t) => t.programId.equals(prog.id)))
              .get();
          for (final r in rows) {
            await stampAndEnqueue(
              SyncEntity.assignment,
              r.id,
              r.hlc,
              (hlc) => (_db.update(_db.assignmentRows)
                    ..where((t) => t.id.equals(r.id)))
                  .write(AssignmentRowsCompanion(hlc: Value(hlc))),
            );
          }
        }
      }
      return count;
    });
  }
}
