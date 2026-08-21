// Seals the invented congregation of `demo_dataset.dart` into restorable
// `.agora` files, so a clean install can be filled with demo data through the
// app's own "restore backup" button — no demo code ships in lib/.
//
//   flutter test tool/demo/generate_demo_backup.dart
//
// Then in the app: Ajustes → Datos → Importar copia, password `agorademo`.
// Wipe the profile once the captures are done.

import 'dart:io';

import 'package:agora/data/backup/backup_service.dart';
import 'package:agora/data/db/app_database.dart';
import 'package:agora/data/sync/hlc.dart';
import 'package:agora/data/sync/sync_scribe.dart';
import 'package:agora/i18n/strings.g.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_dataset.dart';

const demoBackupPassword = 'agorademo';

String _outPath(AppLocale locale) => 'build/demo/demo-${locale.languageCode}.agora';

BackupService _service(AppDatabase db, String device) =>
    BackupService(db, SyncScribe(db, HlcClock(device)));

void main() {
  for (final locale in const [AppLocale.es, AppLocale.en]) {
    final path = _outPath(locale);
    final data = demoDataFor(locale);

    test('writes $path', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await seedDemoData(db, locale: locale);
      final bytes = await _service(db, 'demoSeed').export(demoBackupPassword);

      final out = File(path);
      await out.parent.create(recursive: true);
      await out.writeAsBytes(bytes);

      expect(await out.length(), greaterThan(0));
      // ignore: avoid_print
      print('WROTE ${out.absolute.path} (password: $demoBackupPassword)');
    });

    // Restoring is what the captures actually depend on: prove the bundle
    // lands on a clean device before it goes near a store listing.
    test('$path restores onto a clean device', () async {
      final bytes = await File(path).readAsBytes();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final applied =
          await _service(db, 'demoRestore').import(bytes, demoBackupPassword);

      expect(applied, greaterThan(0));
      expect(await db.select(db.people).get(), hasLength(data.people.length));
      final programs =
          data.projects.fold<int>(0, (n, p) => n + p.weekDates.length);
      expect(await db.select(db.programs).get(), hasLength(programs));
      expect(await db.select(db.projects).get(), hasLength(data.projects.length));
      expect(await db.select(db.assignmentRows).get(), isNotEmpty);
      final congregation = await db.select(db.congregations).getSingle();
      expect(congregation.name, data.congregationName);
    });
  }
}
