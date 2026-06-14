import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import 'db_key_manager.dart';

/// Abre la BD cifrada (SQLite3MultipleCiphers, seleccionado por el bloque
/// `hooks` del pubspec). La clave se lee del llavero ANTES de crear el
/// ejecutor: el callback `setup` corre en un isolate de fondo donde los
/// platform channels (flutter_secure_storage) no funcionan.
QueryExecutor abrirEjecutorCifrado(DbKeyManager keys) {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final file =
        File('${dir.path}${Platform.pathSeparator}participants.db');
    final keyHex = await keys.getOrCreateKeyHex();

    return NativeDatabase.createInBackground(
      file,
      setup: (raw) {
        // Canario 1: el binario debe traer cifrado (sqlite3mc). Un sqlite3
        // normal devolvería vacío y la BD quedaría EN CLARO sin avisar.
        final cipher = raw.select('PRAGMA cipher;');
        if (cipher.isEmpty) {
          throw StateError(
              'sqlite3 sin soporte de cifrado: revisa el bloque hooks '
              'del pubspec (source: sqlite3mc).');
        }
        raw.execute("PRAGMA key = '$keyHex';");
        // Canario 2: con clave errónea esta consulta lanza (archivo ilegible).
        raw.select('SELECT count(*) FROM sqlite_master;');
      },
    );
  });
}
