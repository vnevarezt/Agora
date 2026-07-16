import 'package:drift/drift.dart';

import '../../../models/person.dart';
import '../converters.dart';
import 'congregations.dart';
import 'sync_columns.dart';

/// Person directory table. Maps to the pure model [Person]; enums are
/// stored as TEXT (readable in exports/debug and stable against enum
/// reordering). Replaces the v1 `participants` table — see the migration
/// in `app_database.dart`.
@UseRowClass(Person, generateInsertable: true)
@TableIndex(name: 'people_congregation_idx', columns: {#congregationId})
class People extends Table with SyncColumns {
  TextColumn get congregationId => text().references(Congregations, #id)();

  TextColumn get firstName => text().withDefault(const Constant(''))();
  TextColumn get lastName => text().withDefault(const Constant(''))();
  TextColumn get displayName => text().withLength(min: 1, max: 60)();

  TextColumn get gender => textEnum<Gender>()();
  TextColumn get privilege => textEnum<Role>()();

  /// JSON array of slot-kind ids (see [Person.qualifications]).
  TextColumn get qualifications => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();

  /// Free-text home congregation for visitors; '' for local members.
  TextColumn get originCongregation =>
      text().withDefault(const Constant(''))();

  BoolColumn get active => boolean().withDefault(const Constant(true))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get lastUsed => dateTime().nullable()();
}
