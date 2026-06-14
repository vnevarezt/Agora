import 'package:drift/drift.dart';

import '../../models/participant.dart';
import 'participants_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Base de datos local (SQLite cifrado con SQLite3MultipleCiphers en
/// producción — ver `connection.dart`). El ejecutor se INYECTA para que los
/// tests usen `NativeDatabase.memory()` sin llavero ni cifrado.
@DriftDatabase(tables: [Participants], daos: [ParticipantsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}
