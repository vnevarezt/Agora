import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/data/sync/hlc.dart';
import 'package:jw_program/data/sync/sync_scribe.dart';
import 'package:jw_program/data/sync/sync_seeder.dart';
import 'package:jw_program/models/person.dart' show Gender, Role;

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> insertCongregation(String id, {String? hlc}) =>
      db.into(db.congregations).insert(CongregationsCompanion.insert(
            id: id,
            name: 'C',
            number: const Value('1'),
            color: 0,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
            hlc: Value(hlc),
          ));

  Future<void> insertPerson(String id, String cid, {String? hlc}) =>
      db.into(db.people).insert(PeopleCompanion.insert(
            id: id,
            congregationId: cid,
            displayName: 'P',
            gender: Gender.male,
            privilege: Role.publisher,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
            hlc: Value(hlc),
          ));

  SyncSeeder seeder() => SyncSeeder(db, SyncScribe(db, HlcClock('devSeed')));

  test('seeds every row in the congregation and stamps missing HLCs',
      () async {
    await insertCongregation('c1'); // no hlc
    await insertPerson('p1', 'c1'); // no hlc
    await insertPerson('p2', 'c1', hlc: 'already-stamped');

    final count = await seeder().seedCongregation('c1');
    expect(count, 3); // congregation + 2 people

    // Every outbox entry points at c1's rows.
    final outbox = await db.select(db.outbox).get();
    expect(outbox.map((e) => e.entityId).toSet(), {'c1', 'p1', 'p2'});
    // The previously-unstamped rows now carry an HLC.
    final cong = await (db.select(db.congregations)
          ..where((t) => t.id.equals('c1')))
        .getSingle();
    expect(cong.hlc, isNotNull);
    // The already-stamped row keeps its stamp.
    final p2 =
        await (db.select(db.people)..where((t) => t.id.equals('p2'))).getSingle();
    expect(p2.hlc, 'already-stamped');
  });

  test('ignores rows of other congregations', () async {
    await insertCongregation('c1');
    await insertCongregation('c2');
    await insertPerson('p1', 'c1');
    await insertPerson('p2', 'c2');

    await seeder().seedCongregation('c1');
    final outbox = await db.select(db.outbox).get();
    expect(outbox.map((e) => e.entityId).toSet(), {'c1', 'p1'});
  });

  test('missing congregation seeds nothing', () async {
    expect(await seeder().seedCongregation('nope'), 0);
    expect(await db.select(db.outbox).get(), isEmpty);
  });
}
