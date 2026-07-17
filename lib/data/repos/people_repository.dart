import '../../models/person.dart';
import '../db/app_database.dart';
import '../sync/sync_scribe.dart';
import 'congregations_repository.dart';

/// Domain API over the person directory. THE write path for people: it
/// stamps HLC + outbox (docs/PHASE3_SYNC_SCAFFOLDING.md), so providers/UI
/// must never talk to the DAO directly.
class PeopleRepository {
  PeopleRepository(this._db, this._congregations, this._scribe);

  final AppDatabase _db;
  final CongregationsRepository _congregations;
  final SyncScribe _scribe;

  Stream<List<Person>> watchAll() => _db.peopleDao.watchAll();

  Future<List<Person>> all() => _db.peopleDao.all();

  /// User edit: stamps `updatedAt` and resolves the congregation FK when
  /// the caller doesn't know it yet ('' = "my congregation").
  Future<void> save(Person p) async {
    final congregationId = p.congregationId.isEmpty
        ? await _congregations.ensureDefault()
        : p.congregationId;
    final hlc = await _scribe.nextHlc();
    await _db.transaction(() async {
      await _db.peopleDao.upsert(p.copyWith(
        congregationId: congregationId,
        updatedAt: DateTime.now().toUtc(),
        hlc: hlc,
      ));
      await _scribe.enqueue(SyncEntity.person, p.id, hlc);
    });
  }

  /// Bookkeeping, NOT an edit: only `lastUsed` moves (see PeopleDao) and
  /// no outbox entry — it travels with the row's next real edit.
  Future<void> markUsed(String id) =>
      _db.peopleDao.markUsed(id, DateTime.now().toUtc());

  Future<void> setActive(String id, bool v) async {
    final hlc = await _scribe.nextHlc();
    await _db.transaction(() async {
      await _db.peopleDao.setActive(id, v, DateTime.now().toUtc(), hlc: hlc);
      await _scribe.enqueue(SyncEntity.person, id, hlc);
    });
  }

  Future<void> delete(String id) async {
    final hlc = await _scribe.nextHlc();
    await _db.transaction(() async {
      await _db.peopleDao.softDelete(id, DateTime.now().toUtc(), hlc: hlc);
      await _scribe.enqueue(SyncEntity.person, id, hlc);
    });
  }
}
