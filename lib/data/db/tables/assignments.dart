import 'package:drift/drift.dart';

import '../../../models/hall.dart';
import 'people.dart';
import 'programs.dart';
import 'sync_columns.dart';

/// One filled slot position of a program (docs/PHASE2_PROGRAMS_IN_DB.md):
/// `slotKey` is the stable derived row id ('chairman', 'te0', 'se1'…),
/// [hall]+[position] locate the name inside that row. Fine-grained rows on
/// purpose — two people editing different parts never conflict when sync
/// arrives (DATA_ARCHITECTURE.md §4).
///
/// No unique constraint on (program, slot, hall, position): soft deletes
/// leave tombstones behind, so writers resolve the alive row themselves.
@DataClassName('AssignmentRecord')
@TableIndex(name: 'assignments_program_idx', columns: {#programId})
class AssignmentRows extends Table with SyncColumns {
  @override
  String get tableName => 'assignments';

  TextColumn get programId => text().references(Programs, #id)();
  TextColumn get slotKey => text()();
  TextColumn get hall => textEnum<Hall>()();
  IntColumn get position => integer()();
  TextColumn get displayName => text()();

  /// Link into the person directory; null = free text (visitors, or picks
  /// made before the picker returns ids — phase-2 default).
  TextColumn get personId => text().nullable().references(People, #id)();
}
