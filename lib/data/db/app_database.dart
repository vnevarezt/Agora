import 'package:drift/drift.dart';

import '../../models/person.dart';
import '../../models/week_type.dart';
import '../../models/hall.dart';
import 'converters.dart';
import 'people_dao.dart';
import 'tables/assignments.dart';
import 'tables/congregations.dart';
import 'tables/outbox.dart';
import 'tables/people.dart';
import 'tables/person_absences.dart';
import 'tables/programs.dart';
import 'tables/projects.dart';

part 'app_database.g.dart';

/// Local database (SQLite encrypted with SQLite3MultipleCiphers in production —
/// see `connection.dart`). The executor is INJECTED so tests can use
/// `NativeDatabase.memory()` without keychain or encryption.
@DriftDatabase(
  tables: [
    Congregations,
    People,
    PersonAbsences,
    Projects,
    Programs,
    AssignmentRows,
    Outbox,
    SyncState,
  ],
  daos: [PeopleDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        beforeOpen: (details) async {
          // Soft deletes make FK violations rare, but the hard paths
          // (replaceAll, reset) must still be caught early.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
