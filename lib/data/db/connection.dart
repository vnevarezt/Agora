import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

/// The encrypted database file. Exposed so the "forgot password" reset can
/// delete it together with the key material.
Future<File> databaseFile() async {
  final dir = await getApplicationSupportDirectory();
  await dir.create(recursive: true);
  return File('${dir.path}${Platform.pathSeparator}participants.db');
}

/// Opens the encrypted DB (SQLite3MultipleCiphers, selected by the pubspec
/// `hooks` block). [keyHex] is the already-unwrapped DEK: the key must be
/// obtained BEFORE creating the executor because the `setup` callback runs on
/// a background isolate where platform channels don't work.
QueryExecutor openEncryptedExecutor(String keyHex) {
  return LazyDatabase(() async {
    final file = await databaseFile();

    return NativeDatabase.createInBackground(
      file,
      setup: (raw) {
        // Canary 1: the binary must ship with encryption (sqlite3mc). A plain
        // sqlite3 would return empty and the DB would stay IN CLEAR silently.
        final cipher = raw.select('PRAGMA cipher;');
        if (cipher.isEmpty) {
          throw StateError(
              'sqlite3 sin soporte de cifrado: revisa el bloque hooks '
              'del pubspec (source: sqlite3mc).');
        }
        raw.execute("PRAGMA key = '$keyHex';");
        // Canary 2: with a wrong key this query throws (unreadable file).
        raw.select('SELECT count(*) FROM sqlite_master;');
      },
    );
  });
}
