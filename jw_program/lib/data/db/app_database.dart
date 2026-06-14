import 'package:drift/drift.dart';

import '../../models/participant.dart';
import 'participants_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Local database (SQLite encrypted with SQLite3MultipleCiphers in production —
/// see `connection.dart`). The executor is INJECTED so tests can use
/// `NativeDatabase.memory()` without keychain or encryption.
@DriftDatabase(tables: [Participants], daos: [ParticipantsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}
