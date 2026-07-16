// PeopleRepository + PersonActions on an in-memory DB: the default
// congregation bootstrap and the picker's record-usage semantics.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/models/person.dart';
import 'package:jw_program/state/db_provider.dart';
import 'package:jw_program/state/people_provider.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);
  });

  Person person(String id, String name) => Person(
        id: id,
        congregationId: '',
        firstName: '',
        lastName: '',
        displayName: name,
        gender: Gender.male,
        privilege: Role.publisher,
        qualifications: const [],
        originCongregation: '',
        active: true,
        notes: '',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

  test('save resolves the empty congregation FK to one default congregation',
      () async {
    final repo = container.read(peopleRepositoryProvider);
    await repo.save(person('p1', 'Ana'));
    await repo.save(person('p2', 'Luis'));

    final congs = await db.select(db.congregations).get();
    expect(congs, hasLength(1), reason: 'get-or-create must not duplicate');

    final people = await repo.all();
    expect(people.map((p) => p.congregationId).toSet(), {congs.single.id});
    // save() is a user edit: updatedAt gets stamped.
    expect(people.first.updatedAt.isAfter(DateTime.utc(2026, 1, 1)), true);
  });

  test('recordUsage reuses existing names (normalized) and only then creates',
      () async {
    final actions = container.read(personActionsProvider);
    final repo = container.read(peopleRepositoryProvider);

    await repo.save(person('p1', 'Raúl Espinoza'));
    await actions.recordUsage('raul espinoza'); // same name, no accents

    var people = await repo.all();
    expect(people, hasLength(1), reason: 'must not duplicate the entry');
    expect(people.single.lastUsed, isNotNull);
    // Usage is bookkeeping: updatedAt must NOT move beyond the save() stamp.
    final stamped = people.single.updatedAt;

    await actions.recordUsage('Nuevo Hermano');
    people = await repo.all();
    expect(people, hasLength(2));
    final created =
        people.singleWhere((p) => p.displayName == 'Nuevo Hermano');
    expect(created.isIncomplete, true, reason: 'gender stays unspecified');
    expect(created.lastUsed, isNotNull);
    expect(
      people.singleWhere((p) => p.id == 'p1').updatedAt,
      stamped,
      reason: 'recordUsage must never clobber edit stamps',
    );
  });

  test('delete is soft: gone from reads, tombstone kept', () async {
    final repo = container.read(peopleRepositoryProvider);
    await repo.save(person('p1', 'Ana'));
    await repo.delete('p1');

    expect(await repo.all(), isEmpty);
    final raw = await db.customSelect('SELECT deleted_at FROM people').get();
    expect(raw, hasLength(1));
    expect(raw.single.read<String?>('deleted_at'), isNotNull);
  });
}
