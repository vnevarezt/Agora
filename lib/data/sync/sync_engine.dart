import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'content_crypto.dart';
import 'entity_codec.dart';
import 'sync_scribe.dart';
import 'sync_transport.dart';

/// One [SyncEngine.pullOnce] page. [fetched] drives the drain loop (a full
/// page means there may be more); [applied] is what actually changed rows
/// (echoes and LWW losers fetch but don't apply).
class PullResult {
  const PullResult({
    required this.fetched,
    required this.applied,
    this.undecryptable = 0,
  });

  final int fetched;
  final int applied;

  /// Docs skipped because their blob wouldn't open (corrupt or injected).
  /// They never block the batch or the cursor.
  final int undecryptable;
}

/// Push/pull engine (phase 4a, docs/PHASE4_CLOUD_SYNC.md). Cloud-agnostic:
/// everything network-shaped lives behind [SyncTransport]; everything
/// key-shaped behind [keyringFor] (4b plugs the real key storage in).
class SyncEngine {
  SyncEngine(
    this._db,
    this._transport,
    this._crypto, {
    required this.deviceId,
    required this.keyringFor,
  });

  final AppDatabase _db;
  final SyncTransport _transport;
  final ContentCrypto _crypto;
  final String deviceId;

  /// Keys this member holds for a congregation; null = not syncable (not
  /// shared/enabled), its outbox entries stay queued.
  final Future<CongregationKeyring?> Function(String congregationId)
      keyringFor;

  late final EntityCodec _codec = EntityCodec(_db);

  /// Drains the outbox in id order, coalescing entries per entity (the doc
  /// carries CURRENT row state, so only the newest matters) and batching one
  /// atomic upsert per congregation (one rules evaluation + one activity
  /// bump per push instead of per doc). Pushed entries are deleted after the
  /// batch commits; a crash in between just re-pushes the same state
  /// (idempotent LWW). Returns the number of docs pushed.
  Future<int> pushOnce() async {
    final entries = await (_db.select(_db.outbox)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    if (entries.isEmpty) return 0;

    // Dart map literals keep insertion order (= outbox id order).
    final groups = <(String, String), List<OutboxEntry>>{};
    for (final e in entries) {
      groups.putIfAbsent((e.entity, e.entityId), () => []).add(e);
    }

    // Per congregation: docs to upsert, their activity scopes, and the
    // outbox ids to delete once the batch lands.
    final batches =
        <String, (List<ItemDoc>, Set<String>, List<int>)>{};
    final keyrings = <String, CongregationKeyring?>{};

    for (final MapEntry(key: (entityName, entityId), value: group)
        in groups.entries) {
      Future<void> drop() => (_db.delete(_db.outbox)
            ..where((t) => t.id.isIn([for (final e in group) e.id])))
          .go();

      final entity = SyncEntity.values.byName(entityName);
      final congregationId = await _codec.congregationOf(entity, entityId);
      final payload =
          congregationId == null ? null : await _codec.encode(entity, entityId);
      if (congregationId == null || payload == null) {
        // Broken chain (corrupt outbox): unpushable forever, drop it.
        await drop();
        continue;
      }

      final keyring = keyrings.containsKey(congregationId)
          ? keyrings[congregationId]
          : keyrings[congregationId] = await keyringFor(congregationId);
      if (keyring == null) continue; // not syncable yet: stays queued

      final hlc = await _codec.hlcOf(entity, entityId) ?? group.last.hlc;
      final blob = await _crypto.encrypt(
        keyring: keyring,
        congregationId: congregationId,
        entityId: entityId,
        payload: payload,
      );
      final (docs, scopes, outboxIds) = batches.putIfAbsent(
          congregationId, () => ([], <String>{}, []));
      docs.add(ItemDoc(
        entityId: entityId,
        entity: entityName,
        programTypeId: await _codec.programTypeOf(entity, entityId),
        hlc: hlc,
        srcDevice: deviceId,
        keyVersion: keyring.currentVersion,
        blob: blob,
      ));
      final scope = await _codec.scopeOf(entity, entityId);
      if (scope != null) scopes.add(scope);
      outboxIds.addAll([for (final e in group) e.id]);
    }

    var pushed = 0;
    for (final MapEntry(key: congregationId, value: (docs, scopes, outboxIds))
        in batches.entries) {
      await _transport.upsertItems(congregationId, docs, scopes);
      await (_db.delete(_db.outbox)..where((t) => t.id.isIn(outboxIds))).go();
      pushed += docs.length;
    }
    return pushed;
  }

  /// Entities in FK-dependency order so one batch applies cleanly.
  static const _applyOrder = [
    SyncEntity.congregation,
    SyncEntity.person,
    SyncEntity.personAbsence,
    SyncEntity.project,
    SyncEntity.program,
    SyncEntity.assignment,
  ];

  /// Pulls one page for a congregation since its cursor and LWW-applies.
  /// Callers drain by looping while `fetched > 0` (the transport may page).
  Future<PullResult> pullOnce(String congregationId) async {
    const empty = PullResult(fetched: 0, applied: 0);
    final keyring = await keyringFor(congregationId);
    if (keyring == null) return empty;

    final state = await (_db.select(_db.syncState)
          ..where((t) => t.congregationId.equals(congregationId)))
        .getSingleOrNull();
    final docs =
        await _transport.pullSince(congregationId, state?.pullCursor);
    if (docs.isEmpty) return empty;

    var applied = 0;
    var skipped = 0;
    await _db.transaction(() async {
      for (final kind in _applyOrder) {
        for (final doc in docs) {
          if (doc.entity != kind.name) continue;
          if (doc.srcDevice == deviceId) continue; // own write echoed back
          final localHlc = await _codec.hlcOf(kind, doc.entityId);
          // LWW on the sortable HLC string; an unstamped local row loses.
          if (localHlc != null && localHlc.compareTo(doc.hlc) >= 0) continue;
          final Map<String, dynamic> payload;
          try {
            payload = await _crypto.decrypt(
              keyring: keyring,
              keyVersion: doc.keyVersion,
              congregationId: congregationId,
              entityId: doc.entityId,
              blob: doc.blob,
            );
          } on ContentDecryptException {
            // A doc we can't open must never abort the batch or hold the
            // cursor: one injected/corrupt blob would otherwise wedge this
            // congregation's sync forever (a cheap denial of service for
            // anyone who can write to the collection). Skip and move on.
            // NOTE for when key rotation lands: an unknown keyVersion is
            // transient (we just haven't fetched the new key), so that case
            // must trigger a keyring refresh + re-pull instead of skipping.
            skipped++;
            continue;
          }
          await _codec.apply(kind, doc.entityId, payload, doc.hlc);
          applied++;
        }
      }
      await _db.into(_db.syncState).insertOnConflictUpdate(
            SyncStateCompanion.insert(
              congregationId: congregationId,
              pullCursor: Value(docs.last.serverTs),
              updatedAt: DateTime.now().toUtc(),
            ),
          );
    });
    return PullResult(
        fetched: docs.length, applied: applied, undecryptable: skipped);
  }
}
