import 'package:drift/drift.dart';

import '../../../models/week_type.dart';
import 'projects.dart';
import 'sync_columns.dart';

/// One emission of one program type for one week ("VMC — week of Jul 21").
/// Phase 1 only creates SKELETON rows when the project modal picks weeks;
/// slots and assignments arrive in phase 2 (docs/DATA_ARCHITECTURE.md §2).
@DataClassName('ProgramRecord')
@TableIndex(name: 'programs_project_idx', columns: {#projectId})
class Programs extends Table with SyncColumns {
  TextColumn get projectId => text().references(Projects, #id)();

  /// Stable id from the code registry ('mwb-s140'); never an enum in data
  /// so new program types don't require migrations.
  TextColumn get programTypeId => text()();

  TextColumn get weekType =>
      textEnum<WeekType>().withDefault(Constant(WeekType.normal.name))();

  /// Week identifier as the notebook catalog exposes it (ISO `yyyy-MM-dd`
  /// week start). TEXT: a calendar week, not an instant.
  TextColumn get date => text()();

  /// Optional user-facing override ("Visita del superintendente").
  TextColumn get label => text().withDefault(const Constant(''))();
}
