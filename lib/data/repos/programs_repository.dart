import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../models/hall.dart';
import '../../models/week.dart';
import '../../models/week_type.dart';
import '../db/app_database.dart';

/// Domain API over a project's programs and their assignments (phase 2,
/// docs/PHASE2_PROGRAMS_IN_DB.md). THE write path phase 3 instruments with
/// HLC + outbox.
class ProgramsRepository {
  ProgramsRepository(this._db);

  final AppDatabase _db;

  SimpleSelectStatement<$ProgramsTable, ProgramRecord> _aliveByProject(
          String projectId) =>
      _db.select(_db.programs)
        ..where((t) => t.projectId.equals(projectId) & t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.sortIndex)]);

  Future<List<ProgramRecord>> byProject(String projectId) =>
      _aliveByProject(projectId).get();

  Stream<List<ProgramRecord>> watchByProject(String projectId) =>
      _aliveByProject(projectId).watch();

  /// Snapshot bookkeeping, NOT a user edit: `updatedAt` stays untouched so
  /// merely opening a project never moves the dashboard "edited" label.
  Future<void> setContent(String programId, Week week) {
    return (_db.update(_db.programs)..where((t) => t.id.equals(programId)))
        .write(ProgramsCompanion(
      contentJson: Value(jsonEncode(week.toJson())),
    ));
  }

  Future<void> setWeekType(String programId, WeekType weekType) {
    return (_db.update(_db.programs)..where((t) => t.id.equals(programId)))
        .write(ProgramsCompanion(
      weekType: Value(weekType),
      updatedAt: Value(DateTime.now().toUtc()),
    ));
  }

  Future<void> setTitleOverrides(
      String programId, Map<String, String> overrides) {
    return (_db.update(_db.programs)..where((t) => t.id.equals(programId)))
        .write(ProgramsCompanion(
      titleOverridesJson: Value(jsonEncode(overrides)),
      updatedAt: Value(DateTime.now().toUtc()),
    ));
  }

  /// Meeting config. The editor exposes ONE toggle/values for the whole
  /// project (current UX), so this writes every alive program of it; only
  /// the provided fields change.
  Future<void> setProjectConfig(
    String projectId, {
    String? startTime,
    int? durationMinutes,
    bool? auxRoom,
  }) {
    return (_db.update(_db.programs)
          ..where(
              (t) => t.projectId.equals(projectId) & t.deletedAt.isNull()))
        .write(ProgramsCompanion(
      startTime: startTime == null ? const Value.absent() : Value(startTime),
      durationMinutes: durationMinutes == null
          ? const Value.absent()
          : Value(durationMinutes),
      auxRoom: auxRoom == null ? const Value.absent() : Value(auxRoom),
      updatedAt: Value(DateTime.now().toUtc()),
    ));
  }

  Future<List<AssignmentRecord>> assignmentsByPrograms(
      List<String> programIds) {
    if (programIds.isEmpty) return Future.value(const []);
    return (_db.select(_db.assignmentRows)
          ..where((t) => t.programId.isIn(programIds) & t.deletedAt.isNull()))
        .get();
  }

  /// Writes the whole name list of one slot row in one hall: empty names
  /// tombstone their position, new names insert, changed names update.
  /// Positions beyond [names] are tombstoned too (a slot that shrank).
  Future<void> saveSlotNames({
    required String programId,
    required String slotKey,
    required Hall hall,
    required List<String> names,
  }) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      final existing = await (_db.select(_db.assignmentRows)
            ..where((t) =>
                t.programId.equals(programId) &
                t.slotKey.equals(slotKey) &
                t.hall.equals(hall.name) &
                t.deletedAt.isNull()))
          .get();
      final byPosition = {for (final a in existing) a.position: a};

      Future<void> tombstone(String id) =>
          (_db.update(_db.assignmentRows)..where((t) => t.id.equals(id)))
              .write(AssignmentRowsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ));

      for (var i = 0; i < names.length; i++) {
        final name = names[i].trim();
        final current = byPosition[i];
        if (name.isEmpty) {
          if (current != null) await tombstone(current.id);
        } else if (current == null) {
          await _db.into(_db.assignmentRows).insert(
                AssignmentRowsCompanion.insert(
                  id: const Uuid().v4(),
                  programId: programId,
                  slotKey: slotKey,
                  hall: hall,
                  position: i,
                  displayName: name,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        } else if (current.displayName != name) {
          await (_db.update(_db.assignmentRows)
                ..where((t) => t.id.equals(current.id)))
              .write(AssignmentRowsCompanion(
            displayName: Value(name),
            updatedAt: Value(now),
          ));
        }
      }

      for (final a in existing) {
        if (a.position >= names.length) await tombstone(a.id);
      }
    });
  }
}
