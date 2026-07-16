import 'package:drift/drift.dart';

import 'congregations.dart';
import 'sync_columns.dart';

/// Planning container for a period ("Programas Julio 2026"): belongs to
/// exactly one congregation and can mix program types via its programs.
/// Status is DERIVED (docs/PHASE1_LOCAL_PERSISTENCE.md): exported if
/// [exportedAt] is set, complete if every program is fully assigned,
/// draft otherwise — done/total/editedLabel are computed, never stored.
@DataClassName('ProjectRecord')
@TableIndex(name: 'projects_congregation_idx', columns: {#congregationId})
class Projects extends Table with SyncColumns {
  TextColumn get congregationId => text().references(Congregations, #id)();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get exportedAt => dateTime().nullable()();
}
