import 'package:drift/drift.dart';

import 'sync_columns.dart';

/// A congregation: the tenant, sharing and (later) encryption boundary
/// (docs/DATA_ARCHITECTURE.md §2/§9). Projects and people hang off it.
@DataClassName('CongregationRecord')
class Congregations extends Table with SyncColumns {
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get number => text().withDefault(const Constant(''))();

  /// 0xAARRGGBB dot shown in filters/cards (same semantics as the old
  /// in-memory model; the UI wraps it in a Color).
  IntColumn get color => integer()();

  /// Meeting weekday/time, aux-class count, circuit + CO name… consumed by
  /// the program templates (phase 2). JSON so template-driven settings can
  /// grow without schema migrations.
  TextColumn get settingsJson => text().withDefault(const Constant('{}'))();
}
