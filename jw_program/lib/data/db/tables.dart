import 'package:drift/drift.dart';

import '../../models/participant.dart';

/// Tabla del directorio de participants. Mapea al modelo puro [Participant];
/// los enums se guardan como TEXTO (legible en exports/debug y estable
/// ante reordenamientos del enum).
@UseRowClass(Participant, generateInsertable: true)
class Participants extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get gender => textEnum<Gender>()();
  TextColumn get role => textEnum<Role>()();
  TextColumn get congregation => text().withDefault(const Constant(''))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastUsed => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
