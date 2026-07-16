import 'package:drift/drift.dart';

import '../../models/person.dart';
import 'app_database.dart';
import 'tables/people.dart';

part 'people_dao.g.dart';

/// Operations on the person directory. Fine-grained filtering
/// (accent-insensitive search, privilege, congregation) is derived in Dart
/// from [watchAll] — the dataset is small and SQLite doesn't collate
/// accents. Every read excludes tombstones; deletes are soft.
@DriftAccessor(tables: [People])
class PeopleDao extends DatabaseAccessor<AppDatabase> with _$PeopleDaoMixin {
  PeopleDao(super.db);

  SimpleSelectStatement<$PeopleTable, Person> _alive() =>
      select(people)..where((t) => t.deletedAt.isNull());

  Stream<List<Person>> watchAll() {
    return (_alive()..orderBy([(t) => OrderingTerm.asc(t.displayName)]))
        .watch();
  }

  Future<List<Person>> all() {
    return (_alive()..orderBy([(t) => OrderingTerm.asc(t.displayName)]))
        .get();
  }

  /// Inserts or updates by id. The caller is responsible for setting
  /// `updatedAt` when the change is a user edit.
  Future<void> upsert(Person person) =>
      into(people).insertOnConflictUpdate(person.toInsertable());

  /// Marks usage from the picker. ONLY touches `lastUsed`: touching
  /// `updatedAt` would clobber real edits when merging.
  Future<void> markUsed(String id, DateTime when) {
    return (update(people)..where((t) => t.id.equals(id)))
        .write(PeopleCompanion(lastUsed: Value(when)));
  }

  Future<void> setActive(String id, bool v, DateTime when, {String? hlc}) {
    return (update(people)..where((t) => t.id.equals(id))).write(
      PeopleCompanion(
        active: Value(v),
        updatedAt: Value(when),
        hlc: hlc == null ? const Value.absent() : Value(hlc),
      ),
    );
  }

  /// Soft delete: tombstone, kept for FK integrity and future sync.
  Future<void> softDelete(String id, DateTime when, {String? hlc}) {
    return (update(people)..where((t) => t.id.equals(id))).write(
      PeopleCompanion(
        deletedAt: Value(when),
        updatedAt: Value(when),
        hlc: hlc == null ? const Value.absent() : Value(hlc),
      ),
    );
  }

  /// Merge import: bulk upsert in a single transaction.
  Future<void> bulkUpsert(List<Person> items) {
    return transaction(() async {
      await batch((b) {
        b.insertAllOnConflictUpdate(
            people, [for (final p in items) p.toInsertable()]);
      });
    });
  }

  /// Replace import: deletes everything (hard — the file becomes the new
  /// truth, tombstones included) and loads it in one transaction.
  Future<void> replaceAll(List<Person> items) {
    return transaction(() async {
      await delete(people).go();
      await batch((b) {
        b.insertAll(people, [for (final p in items) p.toInsertable()]);
      });
    });
  }

  /// Alive rows only.
  Future<int> count() async {
    final c = countAll();
    final row = await (selectOnly(people)
          ..where(people.deletedAt.isNull())
          ..addColumns([c]))
        .getSingle();
    return row.read(c) ?? 0;
  }
}
