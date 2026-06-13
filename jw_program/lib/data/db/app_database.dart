import 'package:drift/drift.dart';

import '../../models/hermano.dart';
import 'hermanos_dao.dart';
import 'tablas.dart';

part 'app_database.g.dart';

/// Base de datos local (SQLite cifrado con SQLite3MultipleCiphers en
/// producción — ver `conexion.dart`). El ejecutor se INYECTA para que los
/// tests usen `NativeDatabase.memory()` sin llavero ni cifrado.
@DriftDatabase(tables: [Hermanos], daos: [HermanosDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(onCreate: (m) => m.createAll());
}
