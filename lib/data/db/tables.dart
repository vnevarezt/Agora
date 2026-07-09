import 'package:drift/drift.dart';

import '../../models/participant.dart';

/// Participant directory table. Maps to the pure model [Participant];
/// enums are stored as TEXT (readable in exports/debug and stable
/// against enum reordering).
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
