import 'package:drift/drift.dart';

/// Columns shared by every synced table (docs/DATA_ARCHITECTURE.md §2/§4):
/// UUID primary key, UTC audit stamps, soft-delete tombstone and the HLC
/// slot that phase 3 (sync scaffolding) starts filling. Reads must filter
/// `deletedAt IS NULL`; deletes are soft so sync can replicate them later.
mixin SyncColumns on Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();

  /// UTC. Only changes on user edits (never on bookkeeping like `lastUsed`):
  /// it decides the winner when merging imports, and later LWW sync.
  DateTimeColumn get updatedAt => dateTime()();

  /// Tombstone. Non-null = deleted (kept for sync replication + FK safety).
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Hybrid logical clock stamp. Unused until phase 3; present so adding
  /// sync never needs an ALTER on data tables.
  TextColumn get hlc => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
