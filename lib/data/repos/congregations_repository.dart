import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../models/congregation.dart';
import '../db/app_database.dart';

/// Dot colors cycled over new congregations (moved from the old in-memory
/// dashboard controller).
const congregationPalette = <int>[
  0xFF7A2230,
  0xFF3E6651,
  0xFF3F6193,
  0xFF6B4E8A,
  0xFF9A6A2E,
];

/// Domain API over congregations. THE write path for them: later phases
/// stamp HLC + outbox here (docs/DATA_ARCHITECTURE.md §3).
class CongregationsRepository {
  CongregationsRepository(this._db, {required this.defaultName});

  final AppDatabase _db;

  /// Localized fallback used by [ensureDefault] on fresh installs (the
  /// v1→v2 migration covers upgrades).
  final String defaultName;

  SimpleSelectStatement<$CongregationsTable, CongregationRecord> _alive() =>
      _db.select(_db.congregations)
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);

  /// Creation order (new ones append at the end, as the old controller did).
  Stream<List<Congregation>> watchAll() =>
      _alive().watch().map((rows) => [for (final r in rows) _toModel(r)]);

  Future<Congregation> create({
    required String name,
    required String number,
    Map<String, Object?> settings = const {},
  }) async {
    final count = (await _alive().get()).length;
    final now = DateTime.now().toUtc();
    final record = CongregationRecord(
      id: const Uuid().v4(),
      name: name,
      number: number,
      color: congregationPalette[count % congregationPalette.length],
      settingsJson: jsonEncode(settings),
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      hlc: null,
    );
    await _db.into(_db.congregations).insert(record);
    return _toModel(record);
  }

  /// First alive congregation, created on demand: resolves the FK for
  /// records created while no congregation exists yet ('' callers).
  Future<String> ensureDefault() async {
    final existing = await (_alive()..limit(1)).getSingleOrNull();
    if (existing != null) return existing.id;
    return (await create(name: defaultName, number: '')).id;
  }

  Congregation _toModel(CongregationRecord r) =>
      Congregation(id: r.id, name: r.name, number: r.number, color: r.color);
}
