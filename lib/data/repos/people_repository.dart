import '../../models/person.dart';
import '../db/app_database.dart';
import 'congregations_repository.dart';

/// Domain API over the person directory. THE write path for people: later
/// phases stamp HLC + outbox here (docs/DATA_ARCHITECTURE.md §3), so
/// providers/UI must never talk to the DAO directly.
class PeopleRepository {
  PeopleRepository(this._db, this._congregations);

  final AppDatabase _db;
  final CongregationsRepository _congregations;

  Stream<List<Person>> watchAll() => _db.peopleDao.watchAll();

  Future<List<Person>> all() => _db.peopleDao.all();

  /// User edit: stamps `updatedAt` and resolves the congregation FK when
  /// the caller doesn't know it yet ('' = "my congregation").
  Future<void> save(Person p) async {
    final congregationId = p.congregationId.isEmpty
        ? await _congregations.ensureDefault()
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
}
