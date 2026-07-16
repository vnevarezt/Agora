import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../models/person.dart';
import '../../models/week_type.dart';
import '../../models/hall.dart';
import 'converters.dart';
import 'people_dao.dart';
import 'tables/assignments.dart';
import 'tables/congregations.dart';
import 'tables/people.dart';
import 'tables/person_absences.dart';
import 'tables/programs.dart';
import 'tables/projects.dart';

part 'app_database.g.dart';

/// Local database (SQLite encrypted with SQLite3MultipleCiphers in production —
/// see `connection.dart`). The executor is INJECTED so tests can use
/// `NativeDatabase.memory()` without keychain or encryption.
///
/// Schema history:
///   v1: single `participants` table (flat, free-text congregation).
///   v2: phase-1 schema (docs/PHASE1_LOCAL_PERSISTENCE.md) — congregations,
///       people, person_absences, projects, skeleton programs; participants
///       migrated into people + one default congregation, then dropped.
///   v3: phase-2 schema (docs/PHASE2_PROGRAMS_IN_DB.md) — programs gain the
///       content snapshot + per-program config columns; new `assignments`
///       table (one row per filled slot position).
@DriftDatabase(
  tables: [
    Congregations,
    People,
    PersonAbsences,
    Projects,
    Programs,
    AssignmentRows,
  ],
  daos: [PeopleDao],
)
class AppDatabase extends _$AppDatabase {
  /// [defaultCongregationName] is only used by the v1→v2 migration when no
  /// participant carries a usable congregation string (the UI passes the
  /// localized fallback; the Spanish default keeps tests self-contained).
  AppDatabase(super.e, {this.defaultCongregationName = 'Mi congregación'});

  final String defaultCongregationName;

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v1 predates every other table: this step creates them with
            // Migrator.createTable, which always uses the CURRENT schema
            // shape — so the later steps must NOT run on top of it.
            await _migrateV1ToV2(m);
            return;
          }
          if (from < 3) await _migrateV2ToV3(m);
        },
        beforeOpen: (details) async {
          // Runs after migrations: soft deletes make FK violations rare, but
          // hard paths (replaceAll, reset) must still be caught early.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// v1 → CURRENT. One transaction (drift wraps migrations): create every
  /// other table (Migrator.createTable always uses the current shape, which
  /// is why this step replaces the whole chain), move every participant into
  /// `people` under ONE default congregation, keep the old free text in
  /// `originCongregation` when it differs, drop `participants`. Rationale:
  /// the old field mixed the tenant with a visitor's home congregation —
  /// only the first becomes an FK; no tenants are auto-created from stray
  /// strings (plan §"Migration v1→v2").
  Future<void> _migrateV1ToV2(Migrator m) async {
    await m.createTable(congregations);
    await m.createTable(people);
    await m.createTable(personAbsences);
    await m.createTable(projects);
    await m.createTable(programs);
    await m.createTable(assignmentRows);
    await m.createIndex(peopleCongregationIdx);
    await m.createIndex(personAbsencesPersonIdx);
    await m.createIndex(projectsCongregationIdx);
    await m.createIndex(programsProjectIdx);
    await m.createIndex(assignmentsProgramIdx);

    final rows = await customSelect('SELECT * FROM participants').get();
    if (rows.isNotEmpty) {
      // Most frequent congregation string, grouped accent/case-insensitively
      // (that group is the user's own hall in practice). The winning group's
      // most frequent raw spelling becomes the congregation name.
      final groupCounts = <String, int>{};
      final spellings = <String, Map<String, int>>{};
      for (final row in rows) {
        final raw = row.read<String>('congregation').trim();
        if (raw.isEmpty) continue;
        final key = normalizeName(raw);
        groupCounts[key] = (groupCounts[key] ?? 0) + 1;
        final variants = spellings.putIfAbsent(key, () => {});
        variants[raw] = (variants[raw] ?? 0) + 1;
      }

      var congregationName = defaultCongregationName;
      if (groupCounts.isNotEmpty) {
        final topGroup = groupCounts.entries
            .reduce((a, b) => b.value > a.value ? b : a)
            .key;
        congregationName = spellings[topGroup]!
            .entries
            .reduce((a, b) => b.value > a.value ? b : a)
            .key;
      }
      final congregationKey = normalizeName(congregationName);

      final now = DateTime.now().toUtc();
      final congregationId = const Uuid().v4();
      await into(congregations).insert(CongregationsCompanion.insert(
        id: congregationId,
        name: congregationName,
        // First color of the dashboard palette; the cycled assignment for
        // new congregations lands with milestone 3.
        color: 0xFF7A2230,
        createdAt: now,
        updatedAt: now,
      ));

      await batch((b) {
        for (final row in rows) {
          final origin = row.read<String>('congregation').trim();
          b.insert(
            people,
            PeopleCompanion.insert(
              id: row.read<String>('id'),
              congregationId: congregationId,
              displayName: row.read<String>('name'),
              gender: Gender.values.byName(row.read<String>('gender')),
              privilege: Role.values.byName(row.read<String>('role')),
              originCongregation: Value(
                normalizeName(origin) == congregationKey ? '' : origin,
              ),
              active: Value(row.read<bool>('active')),
              notes: Value(row.read<String>('notes')),
              createdAt: row.read<DateTime>('created_at'),
              updatedAt: row.read<DateTime>('updated_at'),
              lastUsed: Value(row.readNullable<DateTime>('last_used')),
            ),
          );
        }
      });
    }

    await m.deleteTable('participants');
  }

  /// v2 → v3 (docs/PHASE2_PROGRAMS_IN_DB.md): programs gain the content
  /// snapshot and per-program config columns; assignments arrive as their
  /// own table. Existing skeleton programs keep NULL content — the snapshot
  /// service fills it the first time their project opens.
  Future<void> _migrateV2ToV3(Migrator m) async {
    await m.addColumn(programs, programs.sortIndex);
    await m.addColumn(programs, programs.contentJson);
    await m.addColumn(programs, programs.titleOverridesJson);
    await m.addColumn(programs, programs.startTime);
    await m.addColumn(programs, programs.durationMinutes);
    await m.addColumn(programs, programs.auxRoom);
    await m.createTable(assignmentRows);
    await m.createIndex(assignmentsProgramIdx);
  }
}
