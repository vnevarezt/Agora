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

  /// ISO Monday the week starts on ('2026-07-06') — THE identity, and the
  /// only one that survives a change of meeting language. Null on rows
  /// written before v6 and on any week whose heading could not be resolved;
  /// the reconciler fills those from the catalog.
  TextColumn get weekStart => text().nullable()();

  /// Week heading as the workbook prints it, e.g. "7-13 DE JULIO". Kept as
  /// the display label and as the fallback the reconciler matches on while
  /// [weekStart] is still null. It is language-dependent, which is exactly
  /// why it stopped being the join key.
  TextColumn get date => text()();

  /// Position within the project (notebook order picked in the modal).
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();

  /// Optional user-facing override ("Visita del superintendente").
  TextColumn get label => text().withDefault(const Constant(''))();

  /// Parsed MWB week snapshotted from the notebook cache (Week.toJson).
  /// Null until the reconciler fills it (phase-1 skeleton rows).
  TextColumn get contentJson => text().nullable()();

  /// Workbook language [contentJson] was taken from ('S' | 'E'). Without it
  /// a snapshot is anonymous and nobody can tell it went stale when the
  /// congregation changed language; with it, stale is just
  /// `contentLang != workbookLangFor(meetingLanguage)`.
  TextColumn get contentLang => text().nullable()();

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
