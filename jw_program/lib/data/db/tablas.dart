import 'package:drift/drift.dart';

import '../../models/hermano.dart';

/// Tabla del directorio de hermanos. Mapea al modelo puro [Hermano];
/// los enums se guardan como TEXTO (legible en exports/debug y estable
/// ante reordenamientos del enum).
@UseRowClass(Hermano, generateInsertable: true)
class Hermanos extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text().withLength(min: 1, max: 60)();
  TextColumn get sexo => textEnum<Sexo>()();
  TextColumn get privilegio => textEnum<Privilegio>()();
  TextColumn get congregacion => text().withDefault(const Constant(''))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  TextColumn get notas => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get ultimoUso => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
