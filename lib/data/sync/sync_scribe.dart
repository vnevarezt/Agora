import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'hlc.dart';

/// Entity kinds an outbox entry can point at (stored as TEXT).
enum SyncEntity { congregation, person, personAbsence, project, program, assignment }

/// Stamps mutations for future sync (phase 3): issues HLC strings and
/// enqueues outbox entries. Repositories call [enqueue] INSIDE the same
/// transaction as the row write, so data and outbox never desync.
class SyncScribe {
  SyncScribe(this._db, this._clock);

  final AppDatabase _db;
  final HlcClock _clock;
  bool _seeded = false;

  /// Next monotonic stamp. First use seeds the clock from the newest
  /// persisted stamp so restarts (or a wall clock that jumped back) never
  /// issue an HLC older than what this device already wrote.
  Future<String> nextHlc() async {
    if (!_seeded) {
      final row = await (_db.select(_db.outbox)
            ..orderBy([(t) => OrderingTerm.desc(t.hlc)])
            ..limit(1))
          .getSingleOrNull();
      final last = row == null ? null : Hlc.tryParse(row.hlc);
      if (last != null) _clock.receive(last);
      _seeded = true;
    }
    return _clock.next().encode();
  }

  Future<void> enqueue(SyncEntity entity, String entityId, String hlc) {
    return _db.into(_db.outbox).insert(OutboxCompanion.insert(
          entity: entity.name,
          entityId: entityId,
          hlc: hlc,
          queuedAt: DateTime.now().toUtc(),
        ));
  }
}
