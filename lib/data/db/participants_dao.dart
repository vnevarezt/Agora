import 'package:drift/drift.dart';

import '../../models/participant.dart';
import 'app_database.dart';
import 'tables.dart';

part 'participants_dao.g.dart';

/// Operations on the participant directory. Fine-grained filtering
/// (accent-insensitive search, role, congregation) is derived in Dart from
/// [watchAll] — the dataset is small and SQLite doesn't collate accents.
@DriftAccessor(tables: [Participants])
class ParticipantsDao extends DatabaseAccessor<AppDatabase>
    with _$ParticipantsDaoMixin {
  ParticipantsDao(super.db);

  Stream<List<Participant>> watchAll() {
    return (select(participants)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<List<Participant>> all() {
    return (select(participants)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Inserts or updates by id. The caller is responsible for setting
  /// `updatedAt` when the change is a user edit.
  Future<void> upsert(Participant participant) =>
      into(participants).insertOnConflictUpdate(participant.toInsertable());

  /// Marks usage from the picker. ONLY touches `lastUsed`: touching
  /// `updatedAt` would clobber real edits when merging.
  Future<void> markUsed(String id, DateTime when) {
    return (update(participants)..where((t) => t.id.equals(id)))
        .write(ParticipantsCompanion(lastUsed: Value(when)));
  }

  Future<void> setActive(String id, bool v, DateTime when) {
    return (update(participants)..where((t) => t.id.equals(id))).write(
      ParticipantsCompanion(active: Value(v), updatedAt: Value(when)),
    );
  }

  Future<void> deleteById(String id) =>
      (delete(participants)..where((t) => t.id.equals(id))).go();

  /// Merge import: bulk upsert in a single transaction.
  Future<void> bulkUpsert(List<Participant> items) {
    return transaction(() async {
      await batch((b) {
        b.insertAllOnConflictUpdate(
            participants, [for (final p in items) p.toInsertable()]);
      });
    });
  }

  /// Replace import: deletes everything and loads the file (transaction: if the
  /// load fails, nothing is lost).
  Future<void> replaceAll(List<Participant> items) {
    return transaction(() async {
      await delete(participants).go();
      await batch((b) {
        b.insertAll(participants, [for (final p in items) p.toInsertable()]);
      });
    });
  }

  Future<int> count() async {
    final c = countAll();
    final row = await (selectOnly(participants)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }
}
