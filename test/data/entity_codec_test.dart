// The wire format for programs gained weekStart and contentLang in v6. Both
// are nullable and read by name, so devices on either side of the upgrade keep
// syncing with each other — which is the only reason `v` did not have to move.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agora/data/db/app_database.dart';
import 'package:agora/data/sync/entity_codec.dart';
import 'package:agora/data/sync/sync_scribe.dart';

void main() {
  late AppDatabase db;
  late EntityCodec codec;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    codec = EntityCodec(db);
  });
  tearDown(() => db.close());

  /// The rows a program hangs off, so the FKs hold.
  Future<void> seedProject() async {
    final now = DateTime.utc(2026, 1, 10);
    await db.into(db.congregations).insert(CongregationsCompanion.insert(
        id: 'c1', name: 'Norte', color: 1, createdAt: now, updatedAt: now));
    await db.into(db.projects).insert(ProjectsCompanion.insert(
        id: 'pr1',
        congregationId: 'c1',
        name: 'Julio',
        createdAt: now,
        updatedAt: now));
  }

  Map<String, dynamic> v5Payload() => {
        'v': 1,
        'projectId': 'pr1',
        'programTypeId': 'mwb-s140',
        'weekType': 'normal',
        'date': '7-13 DE JULIO',
        'sortIndex': 0,
        'label': '',
        'contentJson': null,
        'titleOverridesJson': '{}',
        'startTime': null,
        'durationMinutes': null,
        'auxRoom': null,
        'createdAt': '2026-01-10T10:00:00.000Z',
        'updatedAt': '2026-01-10T10:00:00.000Z',
        'deletedAt': null,
      };

  test('a payload from a peer that predates v6 applies cleanly', () async {
    await seedProject();

    await codec.apply(SyncEntity.program, 'pg1', v5Payload(), 'hlc1');

    final row = await db.select(db.programs).getSingle();
    expect(row.date, '7-13 DE JULIO');
    expect(row.weekStart, isNull);
    expect(row.contentLang, isNull);
  });

  test('the new fields round-trip', () async {
    await seedProject();
    await codec.apply(
      SyncEntity.program,
      'pg1',
      {
        ...v5Payload(),
        'weekStart': '2026-07-06',
        'contentLang': 'E',
        'contentJson': '{"date":"JULY 6-12","weekStart":"2026-07-06"}',
      },
      'hlc1',
    );

    final encoded = await codec.encode(SyncEntity.program, 'pg1');
    expect(encoded!['weekStart'], '2026-07-06');
    expect(encoded['contentLang'], 'E');
  });

  test('a v6 payload keeps every field a v5 reader looks for', () async {
    await seedProject();
    await codec.apply(SyncEntity.program, 'pg1', v5Payload(), 'hlc1');

    final encoded = await codec.encode(SyncEntity.program, 'pg1');

    // A peer still on v5 reads by name and ignores what it does not know, so
    // the guarantee that matters is that nothing it needs went missing.
    expect(encoded!.keys, containsAll(v5Payload().keys));
  });
}
