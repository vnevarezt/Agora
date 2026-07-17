import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../sync/entity_codec.dart';
import '../sync/sync_scribe.dart';
import 'backup_crypto.dart';

/// Full encrypted backup of the user's data (the real feature behind the
/// settings "Datos" card). The bundle rides the same versioned wire maps as
/// sync (EntityCodec) and restoring is an LWW merge — importing an old
/// backup never clobbers newer local edits.
class BackupService {
  BackupService(this._db, this._scribe);

  final AppDatabase _db;
  final SyncScribe _scribe;

  late final EntityCodec _codec = EntityCodec(_db);

  /// FK-dependency order (same as the sync engine's apply order).
  static const _order = [
    SyncEntity.congregation,
    SyncEntity.person,
    SyncEntity.personAbsence,
    SyncEntity.project,
    SyncEntity.program,
    SyncEntity.assignment,
  ];

  Future<List<({String id, String? hlc})>> _rowsOf(SyncEntity entity) async {
    final table = switch (entity) {
      SyncEntity.congregation => 'congregations',
      SyncEntity.person => 'people',
      SyncEntity.personAbsence => 'person_absences',
      SyncEntity.project => 'projects',
      SyncEntity.program => 'programs',
      SyncEntity.assignment => 'assignments',
    };
    // Tombstones included: the merge needs them so deletions survive a
    // backup/restore roundtrip.
    final rows = await _db.customSelect('SELECT id, hlc FROM $table').get();
    return [
      for (final r in rows)
        (id: r.read<String>('id'), hlc: r.read<String?>('hlc')),
    ];
  }

  /// Everything, sealed under [password].
  Future<Uint8List> export(String password) async {
    final items = <Map<String, dynamic>>[];
    for (final entity in _order) {
      for (final row in await _rowsOf(entity)) {
        final payload = await _codec.encode(entity, row.id);
        if (payload == null) continue;
        items.add({
          'entity': entity.name,
          'id': row.id,
          'hlc': row.hlc,
          'data': payload,
        });
      }
    }
    return BackupCrypto.seal({
      'v': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'items': items,
    }, password);
  }

  /// LWW merge: an item applies when the local row is missing or older
  /// (by HLC; both unstamped → the backup wins, it is at least as old a
  /// source of truth as an unstamped local row). Applied rows are stamped
  /// and enqueued so a future cloud sync replicates the restore. Returns
  /// how many rows changed.
  Future<int> import(Uint8List bytes, String password) async {
    final bundle = await BackupCrypto.open(bytes, password);
    final items = (bundle['items'] as List).cast<Map<String, dynamic>>();

    var applied = 0;
    await _db.transaction(() async {
      for (final entity in _order) {
        for (final item in items) {
          if (item['entity'] != entity.name) continue;
          final id = item['id'] as String;
          final itemHlc = item['hlc'] as String?;
          final localHlc = await _codec.hlcOf(entity, id);
          final exists = await _rowExists(entity, id);
          if (exists) {
            // LWW: keep the newer side; an unstamped backup item never
            // overwrites an existing row.
            if (itemHlc == null) continue;
            if (localHlc != null && localHlc.compareTo(itemHlc) >= 0) {
              continue;
            }
          }
          final hlc = itemHlc ?? await _scribe.nextHlc();
          await _codec.apply(
              entity, id, item['data'] as Map<String, dynamic>, hlc);
          await _scribe.enqueue(entity, id, hlc);
          applied++;
        }
      }
    });
    return applied;
  }

  Future<bool> _rowExists(SyncEntity entity, String id) async =>
      await _codec.hlcOf(entity, id) != null ||
      // hlcOf can't distinguish "no row" from "row with NULL hlc":
      (await _db.customSelect(
        'SELECT 1 FROM ${_tableOf(entity)} WHERE id = ? LIMIT 1',
        variables: [Variable.withString(id)],
      ).get())
          .isNotEmpty;

  static String _tableOf(SyncEntity entity) => switch (entity) {
        SyncEntity.congregation => 'congregations',
        SyncEntity.person => 'people',
        SyncEntity.personAbsence => 'person_absences',
        SyncEntity.project => 'projects',
        SyncEntity.program => 'programs',
        SyncEntity.assignment => 'assignments',
      };
}
