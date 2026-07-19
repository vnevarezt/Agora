import 'package:drift/drift.dart';

import '../../models/hall.dart';
import '../../models/person.dart';
import '../../models/week_type.dart';
import '../db/app_database.dart';
import 'sync_scribe.dart';

/// Wire codec for sync payloads (phase 4a, docs/PHASE4_CLOUD_SYNC.md):
/// explicit maps per entity — deliberately NOT the drift-generated
/// serialization, so the wire format can only change on purpose. Every
/// payload carries `v: 1` for future evolution.
///
/// `apply` writes tables DIRECTLY (never through repositories): pulled rows
/// must not re-enqueue outbox entries.
class EntityCodec {
  EntityCodec(this._db);

  final AppDatabase _db;

  static String? _date(DateTime? d) => d?.toUtc().toIso8601String();
  static DateTime? _parseDate(Object? s) =>
      s == null ? null : DateTime.parse(s as String);

  /// Current row → payload map, or null if the row vanished (never happens
  /// with soft deletes; guards a corrupt outbox).
  Future<Map<String, dynamic>?> encode(SyncEntity entity, String id) async {
    switch (entity) {
      case SyncEntity.congregation:
        final r = await (_db.select(_db.congregations)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (r == null) return null;
        return {
          'v': 1,
          'name': r.name,
          'number': r.number,
          'color': r.color,
          'settingsJson': r.settingsJson,
          'createdAt': _date(r.createdAt),
          'updatedAt': _date(r.updatedAt),
          'deletedAt': _date(r.deletedAt),
        };
      case SyncEntity.person:
        final r = await (_db.select(_db.people)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (r == null) return null;
        return {
          'v': 1,
          'congregationId': r.congregationId,
          'firstName': r.firstName,
          'lastName': r.lastName,
          'displayName': r.displayName,
          'gender': r.gender.name,
          'privilege': r.privilege.name,
          'qualifications': r.qualifications,
          'originCongregation': r.originCongregation,
          'active': r.active,
          'notes': r.notes,
          'createdAt': _date(r.createdAt),
          'updatedAt': _date(r.updatedAt),
          'lastUsed': _date(r.lastUsed),
          'deletedAt': _date(r.deletedAt),
        };
      case SyncEntity.personAbsence:
        final r = await (_db.select(_db.personAbsences)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (r == null) return null;
        return {
          'v': 1,
          'personId': r.personId,
          'startDate': r.startDate,
          'endDate': r.endDate,
          'comment': r.comment,
          'createdAt': _date(r.createdAt),
          'updatedAt': _date(r.updatedAt),
          'deletedAt': _date(r.deletedAt),
        };
      case SyncEntity.project:
        final r = await (_db.select(_db.projects)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (r == null) return null;
        return {
          'v': 1,
          'congregationId': r.congregationId,
          'name': r.name,
          'notes': r.notes,
          'exportedAt': _date(r.exportedAt),
          'createdAt': _date(r.createdAt),
          'updatedAt': _date(r.updatedAt),
          'deletedAt': _date(r.deletedAt),
        };
      case SyncEntity.program:
        final r = await (_db.select(_db.programs)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (r == null) return null;
        return {
          'v': 1,
          'projectId': r.projectId,
          'programTypeId': r.programTypeId,
          'weekType': r.weekType.name,
          'date': r.date,
          'sortIndex': r.sortIndex,
          'label': r.label,
          'contentJson': r.contentJson,
          'titleOverridesJson': r.titleOverridesJson,
          'startTime': r.startTime,
          'durationMinutes': r.durationMinutes,
          'auxRoom': r.auxRoom,
          'createdAt': _date(r.createdAt),
          'updatedAt': _date(r.updatedAt),
          'deletedAt': _date(r.deletedAt),
        };
      case SyncEntity.assignment:
        final r = await (_db.select(_db.assignmentRows)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (r == null) return null;
        return {
          'v': 1,
          'programId': r.programId,
          'slotKey': r.slotKey,
          'hall': r.hall.name,
          'position': r.position,
          'displayName': r.displayName,
          'personId': r.personId,
          'createdAt': _date(r.createdAt),
          'updatedAt': _date(r.updatedAt),
          'deletedAt': _date(r.deletedAt),
        };
    }
  }

  /// Upserts the pulled payload as the row's new state, stamping [hlc].
  Future<void> apply(SyncEntity entity, String id,
      Map<String, dynamic> payload, String hlc) async {
    switch (entity) {
      case SyncEntity.congregation:
        await _db.into(_db.congregations).insertOnConflictUpdate(
              CongregationRecord(
                id: id,
                name: payload['name'] as String,
                number: payload['number'] as String,
                color: payload['color'] as int,
                settingsJson: payload['settingsJson'] as String,
                createdAt: _parseDate(payload['createdAt'])!,
                updatedAt: _parseDate(payload['updatedAt'])!,
                deletedAt: _parseDate(payload['deletedAt']),
                hlc: hlc,
              ),
            );
      case SyncEntity.person:
        await _db.into(_db.people).insertOnConflictUpdate(
              Person(
                id: id,
                congregationId: payload['congregationId'] as String,
                firstName: payload['firstName'] as String,
                lastName: payload['lastName'] as String,
                displayName: payload['displayName'] as String,
                gender: Gender.values.byName(payload['gender'] as String),
                privilege:
                    Role.values.byName(payload['privilege'] as String),
                qualifications:
                    (payload['qualifications'] as List).cast<String>(),
                originCongregation:
                    payload['originCongregation'] as String,
                active: payload['active'] as bool,
                notes: payload['notes'] as String,
                createdAt: _parseDate(payload['createdAt'])!,
                updatedAt: _parseDate(payload['updatedAt'])!,
                lastUsed: _parseDate(payload['lastUsed']),
                deletedAt: _parseDate(payload['deletedAt']),
                hlc: hlc,
              ).toInsertable(),
            );
      case SyncEntity.personAbsence:
        await _db.into(_db.personAbsences).insertOnConflictUpdate(
              PersonAbsenceRecord(
                id: id,
                personId: payload['personId'] as String,
                startDate: payload['startDate'] as String,
                endDate: payload['endDate'] as String,
                comment: payload['comment'] as String,
                createdAt: _parseDate(payload['createdAt'])!,
                updatedAt: _parseDate(payload['updatedAt'])!,
                deletedAt: _parseDate(payload['deletedAt']),
                hlc: hlc,
              ),
            );
      case SyncEntity.project:
        await _db.into(_db.projects).insertOnConflictUpdate(
              ProjectRecord(
                id: id,
                congregationId: payload['congregationId'] as String,
                name: payload['name'] as String,
                notes: payload['notes'] as String,
                exportedAt: _parseDate(payload['exportedAt']),
                createdAt: _parseDate(payload['createdAt'])!,
                updatedAt: _parseDate(payload['updatedAt'])!,
                deletedAt: _parseDate(payload['deletedAt']),
                hlc: hlc,
              ),
            );
      case SyncEntity.program:
        await _db.into(_db.programs).insertOnConflictUpdate(
              ProgramRecord(
                id: id,
                projectId: payload['projectId'] as String,
                programTypeId: payload['programTypeId'] as String,
                weekType:
                    WeekType.values.byName(payload['weekType'] as String),
                date: payload['date'] as String,
                sortIndex: payload['sortIndex'] as int,
                label: payload['label'] as String,
                contentJson: payload['contentJson'] as String?,
                titleOverridesJson: payload['titleOverridesJson'] as String,
                startTime: payload['startTime'] as String?,
                durationMinutes: payload['durationMinutes'] as int?,
                auxRoom: payload['auxRoom'] as bool?,
                createdAt: _parseDate(payload['createdAt'])!,
                updatedAt: _parseDate(payload['updatedAt'])!,
                deletedAt: _parseDate(payload['deletedAt']),
                hlc: hlc,
              ),
            );
      case SyncEntity.assignment:
        await _db.into(_db.assignmentRows).insertOnConflictUpdate(
              AssignmentRecord(
                id: id,
                programId: payload['programId'] as String,
                slotKey: payload['slotKey'] as String,
                hall: Hall.values.byName(payload['hall'] as String),
                position: payload['position'] as int,
                displayName: payload['displayName'] as String,
                personId: payload['personId'] as String?,
                createdAt: _parseDate(payload['createdAt'])!,
                updatedAt: _parseDate(payload['updatedAt'])!,
                deletedAt: _parseDate(payload['deletedAt']),
                hlc: hlc,
              ),
            );
    }
  }

  /// Which congregation (tenant/collection) a row belongs to. Null when the
  /// chain is broken (corrupt outbox) — the entry is dropped, not pushed.
  Future<String?> congregationOf(SyncEntity entity, String id) async {
    switch (entity) {
      case SyncEntity.congregation:
        return id;
      case SyncEntity.person:
        final r = await (_db.select(_db.people)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        return r?.congregationId;
      case SyncEntity.personAbsence:
        final r = await (_db.select(_db.personAbsences)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        return r == null
            ? null
            : congregationOf(SyncEntity.person, r.personId);
      case SyncEntity.project:
        final r = await (_db.select(_db.projects)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        return r?.congregationId;
      case SyncEntity.program:
        final r = await (_db.select(_db.programs)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        return r == null
            ? null
            : congregationOf(SyncEntity.project, r.projectId);
      case SyncEntity.assignment:
        final r = await (_db.select(_db.assignmentRows)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        return r == null
            ? null
            : congregationOf(SyncEntity.program, r.programId);
    }
  }

  /// Program type of program/assignment rows (clear ItemDoc metadata so
  /// rules can gate `edit:<type>` capabilities); null for other kinds or a
  /// broken chain.
  Future<String?> programTypeOf(SyncEntity entity, String id) async {
    switch (entity) {
      case SyncEntity.program:
        final r = await (_db.select(_db.programs)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        return r?.programTypeId;
      case SyncEntity.assignment:
        final r = await (_db.select(_db.assignmentRows)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        return r == null
            ? null
            : programTypeOf(SyncEntity.program, r.programId);
      case SyncEntity.congregation:
      case SyncEntity.person:
      case SyncEntity.personAbsence:
      case SyncEntity.project:
        return null;
    }
  }

  /// Activity scope of a row for the sync heartbeat: which "thing" changed,
  /// at the granularity peers care about. Projects (and their programs and
  /// assignments) map to the PROJECT id so a device with that project open
  /// pulls immediately while others defer; the people directory and the
  /// congregation row are their own scopes. Null on a broken chain.
  Future<String?> scopeOf(SyncEntity entity, String id) async {
    switch (entity) {
      case SyncEntity.congregation:
        return 'congregation';
      case SyncEntity.person:
      case SyncEntity.personAbsence:
        return 'people';
      case SyncEntity.project:
        return id;
      case SyncEntity.program:
        final r = await (_db.select(_db.programs)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        return r?.projectId;
      case SyncEntity.assignment:
        final r = await (_db.select(_db.assignmentRows)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        return r == null ? null : scopeOf(SyncEntity.program, r.programId);
    }
  }

  /// The row's current HLC stamp (LWW comparand); null = never stamped,
  /// which loses against any remote stamp.
  Future<String?> hlcOf(SyncEntity entity, String id) async {
    final table = switch (entity) {
      SyncEntity.congregation => _db.congregations,
      SyncEntity.person => _db.people,
      SyncEntity.personAbsence => _db.personAbsences,
      SyncEntity.project => _db.projects,
      SyncEntity.program => _db.programs,
      SyncEntity.assignment => _db.assignmentRows,
    } as TableInfo<dynamic, dynamic>;
    final rows = await _db
        .customSelect(
          'SELECT hlc FROM ${table.actualTableName} WHERE id = ?',
          variables: [Variable.withString(id)],
        )
        .get();
    return rows.isEmpty ? null : rows.single.read<String?>('hlc');
  }
}
