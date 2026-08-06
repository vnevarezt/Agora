import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Drift's WASM backend, stored in OPFS or IndexedDB depending on what the
/// browser offers.
///
/// **This database is not encrypted.** SQLite3MultipleCiphers has no WASM build
/// here, and on the web it would buy little: the web build is cloud-mode only,
/// and cloud mode already keeps the DEK in the clear next to the database
/// (see [DbKeyManager.cloudKeyName]). On native the OS keychain and the file
/// sit in a filesystem other local processes can read, so the cipher is what
/// separates them; in the browser the same-origin policy already is that
/// boundary, and an attacker who can read this origin's storage can read the
/// key alongside it either way.
///
/// What this does cost: data stays readable to anything running on this origin,
/// so an XSS bug exposes the congregation's data rather than just the session.
/// Native builds keep the cipher.
QueryExecutor openEncryptedExecutor(String keyHex) {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: _databaseName,
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}

/// Drops the database so "forgot password" / reset starts from nothing.
Future<void> deleteDatabase() async {
  final probed = await WasmDatabase.probe(
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
    databaseName: _databaseName,
  );
  for (final existing in probed.existingDatabases) {
    if (existing.$2 == _databaseName) await probed.deleteDatabase(existing);
  }
}

const _databaseName = 'agora';
