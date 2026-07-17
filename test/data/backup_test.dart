// Encrypted backup (.agora): password envelope + full export/import with
// LWW merge over the same wire codec sync uses.

import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jw_program/data/backup/backup_crypto.dart';
import 'package:jw_program/data/db/app_database.dart';
import 'package:jw_program/models/congregation_settings.dart';
import 'package:jw_program/models/hall.dart';
import 'package:jw_program/state/backup_provider.dart';
import 'package:jw_program/state/dashboard_provider.dart';
import 'package:jw_program/state/db_provider.dart';
import 'package:jw_program/state/program_content.dart';

ProviderContainer containerFor(AppDatabase db) {
  final c = ProviderContainer(overrides: [dbProvider.overrideWithValue(db)]);
  addTearDown(c.dispose);
  addTearDown(db.close);
  return c;
}

void main() {
  test('crypto envelope: roundtrip, wrong password, wrong file', () async {
    final bytes = await BackupCrypto.seal({'x': 1}, 'secreto');
    expect(await BackupCrypto.open(bytes, 'secreto'), {'x': 1});
    await expectLater(BackupCrypto.open(bytes, 'otra'),
        throwsA(isA<WrongBackupPasswordException>()));
    await expectLater(
        BackupCrypto.open(Uint8List.fromList('not json'.codeUnits), 'x'),
        throwsA(isA<MalformedBackupException>()));
  });

  test('export → import into a fresh DB restores everything', () async {
    final a = containerFor(AppDatabase(NativeDatabase.memory()));
    final cong = await a
        .read(congregationsRepositoryProvider)
        .create(name: 'Norte', number: '7');
    await a
        .read(projectsRepositoryProvider)
        .create(name: 'Julio', congregationId: cong.id, weeks: ['W1']);
    final program =
        (await a.read(projectsRepositoryProvider).watchAll().first)
            .single
            .programs
            .single;
    await a.read(programsRepositoryProvider).saveSlotNames(
        programId: program.id,
        slotKey: 'te0',
        hall: Hall.main,
        names: ['Ana']);

    final bytes = await a.read(backupServiceProvider).export('clave');

    final b = containerFor(AppDatabase(NativeDatabase.memory()));
    final applied = await b.read(backupServiceProvider).import(bytes, 'clave');
    expect(applied, 4); // congregation + project + program + assignment

    final congs = await b.read(congregationsRepositoryProvider).watchAll().first;
    expect(congs.single.name, 'Norte');
    final data =
        (await b.read(projectsRepositoryProvider).watchAll().first).single;
    expect(data.project.name, 'Julio');
    final assignments = await b
        .read(programsRepositoryProvider)
        .assignmentsByPrograms([data.programs.single.id]);
    expect(assignments.single.displayName, 'Ana');

    // Restored rows are queued for a future cloud sync.
    expect((await b.read(dbProvider).select(b.read(dbProvider).outbox).get())
        .length, greaterThanOrEqualTo(4));
  });

  test('LWW merge: an old backup never clobbers newer local edits', () async {
    final a = containerFor(AppDatabase(NativeDatabase.memory()));
    final cong = await a
        .read(congregationsRepositoryProvider)
        .create(name: 'Original', number: '1');
    final bytes = await a.read(backupServiceProvider).export('clave');

    // Local edit AFTER the backup was taken.
    await a.read(congregationsRepositoryProvider).update(cong.id,
        name: 'Renombrada',
        number: '1',
        settings: const CongregationSettings());

    final applied = await a.read(backupServiceProvider).import(bytes, 'clave');
    expect(applied, 0, reason: 'backup rows are older, nothing changes');
    final after =
        await a.read(congregationsRepositoryProvider).watchAll().first;
    expect(after.single.name, 'Renombrada');
  });
}
