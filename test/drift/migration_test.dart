// v1 → v2 migration (docs/PHASE1_LOCAL_PERSISTENCE.md): schema validity via
// drift's SchemaVerifier, plus the data mapping — participants become people
// under ONE default congregation, the old free text survives in
// `originCongregation` only for visitors, and `participants` is dropped.
//
// Regenerate helpers after schema changes:
//   dart run drift_dev schema dump lib/data/db/app_database.dart drift_schemas/
//   dart run drift_dev schema generate drift_schemas/ test/drift/generated/

import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/models/participant.dart';

import 'generated/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('empty v1 migrates to a valid v2 schema', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    await verifier.migrateAndValidate(db, 2);

    // No participants → no auto-created congregation.
    expect(await db.select(db.congregations).get(), isEmpty);
    expect(await db.peopleDao.count(), 0);
    await db.close();
  });

  test('participants become people under one default congregation', () async {
    final schema = await verifier.schemaAt(1);

    // Fixture straight into the v1 file: two spellings of the same hall
    // (accents/case), one visitor, one empty congregation, inactive rows,
    // null last_used. Dates are ISO text (store_date_time_values_as_text).
    schema.rawDatabase.execute('''
      INSERT INTO participants
        (id, name, gender, role, congregation, active, notes,
         created_at, updated_at, last_used)
      VALUES
        ('a1', 'Juan Pérez', 'male', 'elder', 'CONSTITUCIÓN J.A CASTRO', 1,
         'nota', '2026-01-10T10:00:00.000Z', '2026-01-12T10:00:00.000Z',
         '2026-02-01T10:00:00.000Z'),
        ('a2', 'Ana López', 'female', 'publisher', 'CONSTITUCIÓN J.A CASTRO',
         0, '', '2026-01-10T10:00:00.000Z', '2026-01-10T10:00:00.000Z', NULL),
        ('a3', 'Pedro Gómez', 'male', 'ministerialServant',
         'constitución j.a castro', 1, '', '2026-01-11T10:00:00.000Z',
         '2026-01-11T10:00:00.000Z', NULL),
        ('a4', 'Carlos Ruiz', 'male', 'elder', 'Congregación Norte', 1, '',
         '2026-01-11T10:00:00.000Z', '2026-01-11T10:00:00.000Z', NULL),
        ('a5', 'Luis', 'unspecified', 'publisher', '', 1, '',
         '2026-01-11T10:00:00.000Z', '2026-01-11T10:00:00.000Z', NULL);
    ''');

    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);

    // One congregation, named after the dominant spelling of the top group.
    final congs = await db.select(db.congregations).get();
    expect(congs, hasLength(1));
    expect(congs.single.name, 'CONSTITUCIÓN J.A CASTRO');

    final people = {for (final p in await db.peopleDao.all()) p.id: p};
    expect(people, hasLength(5));

    // Everyone belongs to the default congregation (the FK tenant).
    for (final p in people.values) {
      expect(p.congregationId, congs.single.id);
    }

    // Old free text only survives for visitors (normalized comparison).
    expect(people['a1']!.originCongregation, '');
    expect(people['a3']!.originCongregation, '');
    expect(people['a4']!.originCongregation, 'Congregación Norte');
    expect(people['a5']!.originCongregation, '');

    // Field mapping + preserved stamps.
    final juan = people['a1']!;
    expect(juan.displayName, 'Juan Pérez');
    expect(juan.firstName, '');
    expect(juan.lastName, '');
    expect(juan.gender, Gender.male);
    expect(juan.privilege, Role.elder);
    expect(juan.notes, 'nota');
    expect(juan.qualifications, isEmpty);
    expect(juan.createdAt, DateTime.utc(2026, 1, 10, 10));
    expect(juan.updatedAt, DateTime.utc(2026, 1, 12, 10));
    expect(juan.lastUsed, DateTime.utc(2026, 2, 1, 10));
    expect(people['a2']!.active, false);
    expect(people['a2']!.lastUsed, isNull);
    expect(people['a5']!.isIncomplete, true);

    // The v1 table is gone.
    final leftover = await db
        .customSelect("SELECT name FROM sqlite_master WHERE name = 'participants'")
        .get();
    expect(leftover, isEmpty);

    await db.close();
  });

  test('all-empty congregation strings fall back to the localized default',
      () async {
    final schema = await verifier.schemaAt(1);
    schema.rawDatabase.execute('''
      INSERT INTO participants
        (id, name, gender, role, congregation, active, notes,
         created_at, updated_at, last_used)
      VALUES
        ('b1', 'Luis', 'unspecified', 'publisher', '', 1, '',
         '2026-01-11T10:00:00.000Z', '2026-01-11T10:00:00.000Z', NULL);
    ''');

    final db = AppDatabase(
      schema.newConnection(),
      defaultCongregationName: 'Mi congregación',
    );
    await verifier.migrateAndValidate(db, 2);

    final congs = await db.select(db.congregations).get();
    expect(congs.single.name, 'Mi congregación');
    expect((await db.peopleDao.all()).single.originCongregation, '');
    await db.close();
  });
}
