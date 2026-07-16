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

  /// Week identifier as the notebook catalog exposes it (the parsed week
  /// heading, e.g. "7-13 DE JULIO"). TEXT label, NOT sortable — display
  /// order lives in [sortIndex].
  TextColumn get date => text()();

  /// Position within the project (notebook order picked in the modal).
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();

  /// Optional user-facing override ("Visita del superintendente").
  TextColumn get label => text().withDefault(const Constant(''))();

  /// Parsed MWB week snapshotted from the notebook cache (Week.toJson).
  /// Null until the snapshot service fills it (phase-1 skeleton rows).
  TextColumn get contentJson => text().nullable()();

  /// Per-row title edits, JSON map slotKey → title (coarse: they ride the
  /// program row; assignments are the fine-grained ones).
  TextColumn get titleOverridesJson =>
      text().withDefault(const Constant('{}'))();

  /// Per-program meeting config. Null = inherit the congregation settings
  /// (start time / aux room) or the app default (duration 105).
  TextColumn get startTime => text().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  BoolColumn get auxRoom => boolean().nullable()();
}
