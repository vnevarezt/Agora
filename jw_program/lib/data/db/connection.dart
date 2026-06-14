import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'db_key_manager.dart';

/// Opens the encrypted DB (SQLite3MultipleCiphers, selected by the pubspec
/// `hooks` block). The key is read from the keychain BEFORE creating the
/// executor: the `setup` callback runs on a background isolate where platform
/// channels (flutter_secure_storage) don't work.
QueryExecutor openEncryptedExecutor(DbKeyManager keys) {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final file =
        File('${dir.path}${Platform.pathSeparator}participants.db');
    final keyHex = await keys.getOrCreateKeyHex();

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
