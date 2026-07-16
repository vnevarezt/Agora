import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../models/person.dart';
import '../db/app_database.dart';

/// Domain API over the person directory. THE write path for people: later
/// phases stamp HLC + outbox here (docs/DATA_ARCHITECTURE.md §3), so
/// providers/UI must never talk to the DAO directly.
class PeopleRepository {
  PeopleRepository(this._db, {required this.defaultCongregationName});

  final AppDatabase _db;

  /// Localized name used when the directory needs a congregation and none
  /// exists yet (fresh installs; the migration covers upgrades).
  final String defaultCongregationName;

  Stream<List<Person>> watchAll() => _db.peopleDao.watchAll();

  Future<List<Person>> all() => _db.peopleDao.all();

  /// User edit: stamps `updatedAt` and resolves the congregation FK when
  /// the caller doesn't know it yet ('' = "my congregation").
  Future<void> save(Person p) async {
    final congregationId = p.congregationId.isEmpty
        ? await ensureDefaultCongregation()
        : p.congregationId;
    await _db.peopleDao.upsert(p.copyWith(
      congregationId: congregationId,
      updatedAt: DateTime.now().toUtc(),
    ));
  }

  /// Bookkeeping, NOT an edit: only `lastUsed` moves (see PeopleDao).
  Future<void> markUsed(String id) =>
      _db.peopleDao.markUsed(id, DateTime.now().toUtc());

  Future<void> setActive(String id, bool v) =>
      _db.peopleDao.setActive(id, v, DateTime.now().toUtc());

  Future<void> delete(String id) =>
      _db.peopleDao.softDelete(id, DateTime.now().toUtc());

  /// First alive congregation, created on demand. Single-congregation
  /// stopgap until milestone 3 persists congregation management: people
  /// created before that land in the user's own hall.
  Future<String> ensureDefaultCongregation() async {
    final existing = await (_db.select(_db.congregations)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return existing.id;

    final now = DateTime.now().toUtc();
    final id = const Uuid().v4();
    await _db.into(_db.congregations).insert(CongregationsCompanion.insert(
          id: id,
          name: defaultCongregationName,
          // First color of the dashboard palette (cycling arrives with
          // milestone 3, same note as the v1→v2 migration).
          color: 0xFF7A2230,
          createdAt: now,
          updatedAt: now,
        ));
    return id;
  }
}
