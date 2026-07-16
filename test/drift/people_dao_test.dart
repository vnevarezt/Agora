// PeopleDao on an in-memory database (no keychain, no encryption): CRUD
// semantics ported from the old ParticipantsDao plus the phase-1 additions —
// soft deletes filtered everywhere and the congregation FK enforced.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/models/participant.dart';
import 'package:jw_program/models/person.dart';

void main() {
  late AppDatabase db;
  const congId = 'cong-1';
  final t0 = DateTime.utc(2026, 1, 1);

  Person person(String id, String name, {DateTime? updatedAt}) => Person(
        id: id,
        congregationId: congId,
        firstName: '',
        lastName: '',
        displayName: name,
        gender: Gender.male,
        privilege: Role.publisher,
        qualifications: const [],
        originCongregation: '',
        active: true,
        notes: '',
        createdAt: t0,
        updatedAt: updatedAt ?? t0,
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.into(db.congregations).insert(CongregationsCompanion.insert(
          id: congId,
          name: 'Mi congregación',
          color: 0xFF7A2230,
          createdAt: t0,
          updatedAt: t0,
        ));
  });

  tearDown(() => db.close());

  test('upsert + all, ordered by display name', () async {
    await db.peopleDao.upsert(person('p2', 'Zoe'));
    await db.peopleDao.upsert(person('p1', 'Ana'));
    expect((await db.peopleDao.all()).map((p) => p.id), ['p1', 'p2']);
    expect(await db.peopleDao.count(), 2);
  });

  test('markUsed touches lastUsed but never updatedAt', () async {
    await db.peopleDao.upsert(person('p1', 'Ana'));
    final when = DateTime.utc(2026, 2, 1);
    await db.peopleDao.markUsed('p1', when);
    final p = (await db.peopleDao.all()).single;
    expect(p.lastUsed, when);
    expect(p.updatedAt, t0);
  });

  test('setActive stamps updatedAt', () async {
    await db.peopleDao.upsert(person('p1', 'Ana'));
    final when = DateTime.utc(2026, 2, 2);
    await db.peopleDao.setActive('p1', false, when);
    final p = (await db.peopleDao.all()).single;
    expect(p.active, false);
    expect(p.updatedAt, when);
  });

  test('softDelete hides the row from reads but keeps it in the table',
      () async {
    await db.peopleDao.upsert(person('p1', 'Ana'));
    await db.peopleDao.softDelete('p1', DateTime.utc(2026, 2, 3));
    expect(await db.peopleDao.all(), isEmpty);
    expect(await db.peopleDao.count(), 0);
    final raw = await db.customSelect('SELECT id FROM people').get();
    expect(raw, hasLength(1));
  });

  test('replaceAll swaps the whole directory in one transaction', () async {
    await db.peopleDao.upsert(person('p1', 'Ana'));
    await db.peopleDao
        .replaceAll([person('p9', 'Eva'), person('p8', 'Bruno')]);
    expect((await db.peopleDao.all()).map((p) => p.id), ['p8', 'p9']);
  });

  test('congregation FK is enforced', () async {
    final orphan = person('px', 'Sin casa').copyWith(congregationId: 'nope');
    await expectLater(db.peopleDao.upsert(orphan), throwsA(isA<SqliteException>()));
  });
}
