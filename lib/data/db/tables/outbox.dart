import 'package:drift/drift.dart';

/// Dirty-set of locally-mutated entities awaiting push (phase 3,
/// docs/PHASE3_SYNC_SCAFFOLDING.md). NOT an op log: the pusher reads the
/// CURRENT row for [entityId] and replicates its state (LWW), so multiple
/// entries for one entity simply coalesce. The autoincrement id is the
/// push order. Local-only bookkeeping — never synced itself, so no
/// SyncColumns here.
@DataClassName('OutboxEntry')
class Outbox extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Entity kind, the table it points into ('person', 'program'…).
  TextColumn get entity => text()();
  TextColumn get entityId => text()();

  /// Stamp given to the row by this mutation (mirrors the row's hlc).
  TextColumn get hlc => text()();

  DateTimeColumn get queuedAt => dateTime()();
}

/// Per-congregation sync cursors (filled by phase 4): how far this device
/// has pulled and which outbox id it has pushed through. Local-only.
@DataClassName('SyncStateRecord')
class SyncState extends Table {
  TextColumn get congregationId => text()();

  /// Server timestamp watermark of the last completed pull.
  TextColumn get pullCursor => text().nullable()();

  /// Outbox id this congregation's pusher has completed through.
  IntColumn get pushedThrough => integer().nullable()();

  /// Lowest CCK version this device gave up on decrypting, after which the
  /// cursor was allowed past those docs (see [SyncEngine.pullOnce]). Once the
  /// version reaches us, the cursor rewinds to null and the history is
  /// re-pulled. Null = nothing was ever skipped.
  IntColumn get missingKeyVersion => integer().nullable()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {congregationId};
}
