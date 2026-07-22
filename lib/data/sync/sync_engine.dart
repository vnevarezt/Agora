import 'package:drift/drift.dart';

import '../../models/member_capabilities.dart';
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
    this.unknownKeyVersions = const {},
    this.cursorHeld = false,
  });

  final int fetched;
  final int applied;

  /// Docs skipped because their blob wouldn't open (corrupt or injected).
  /// They never block the batch or the cursor.
  final int undecryptable;

  /// Key versions this page carried that we hold no key for — a rotation we
  /// haven't caught up with, or an injected version that will never exist.
  final Set<int> unknownKeyVersions;

  /// True when the cursor was deliberately NOT advanced past this page
  /// because of [unknownKeyVersions]. The caller must refresh the keyring
  /// and retry the SAME page — draining on would spin forever.
  final bool cursorHeld;
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
    this.capabilitiesFor = _unknownCapabilities,
  });

  final AppDatabase _db;
  final SyncTransport _transport;
  final ContentCrypto _crypto;
  final String deviceId;

  /// Keys this member holds for a congregation; null = not syncable (not
  /// shared/enabled), its outbox entries stay queued.
  final Future<CongregationKeyring?> Function(String congregationId)
      keyringFor;

  /// What this member is allowed to write in a congregation. Null = unknown
  /// (membership stream not loaded yet) and means "don't filter": the batch
  /// may bounce, but a stale read must never silently delete the user's
  /// pending edits. See [pushOnce].
  final Future<MemberCapabilities?> Function(String congregationId)
      capabilitiesFor;

  static Future<MemberCapabilities?> _unknownCapabilities(String _) async =>
      null;

  late final EntityCodec _codec = EntityCodec(_db);

  /// Drains the outbox in id order, coalescing entries per entity (the doc
  /// carries CURRENT row state, so only the newest matters) and batching one
  /// atomic upsert per congregation (one rules evaluation + one activity
  /// bump per push instead of per doc). Pushed entries are deleted after the
  /// batch commits; a crash in between just re-pushes the same state
  /// (idempotent LWW). Returns the number of docs pushed.
  ///
  /// Docs this member's [capabilitiesFor] forbid are dropped BEFORE the
  /// batch is built. That is not belt-and-braces on top of the rules — it is
  /// load-bearing: the whole congregation goes up as ONE batch, so a single
  /// doc the rules bounce (a settings edit by a non-admin, say) fails the
  /// commit, leaves every row in the outbox and makes the controller retry
  /// forever, blocking that member's legitimate writes too. Gating the UI
  /// isn't enough — capabilities can be downgraded mid-session.
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
    final capabilities = <String, MemberCapabilities?>{};

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

      final programTypeId = await _codec.programTypeOf(entity, entityId);
      final caps = capabilities.containsKey(congregationId)
          ? capabilities[congregationId]
          : capabilities[congregationId] =
              await capabilitiesFor(congregationId);
      if (caps != null && !caps.canPush(entityName, programTypeId)) {
        // Unpushable for as long as these capabilities hold, and keeping it
        // would block everything behind it. The local row is untouched —
        // only the intent to publish it is dropped.
        await drop();
        continue;
      }

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
        programTypeId: programTypeId,
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
  ///
  /// A doc encrypted with a key version we don't hold HOLDS THE CURSOR
  /// (`cursorHeld`) instead of being skipped: after a rotation, skipping past
  /// it would lose every doc written with the new key, permanently. The
  /// caller refreshes the keyring and retries the same page.
  ///
  /// [acceptUnknownKeyVersions] is the escape hatch for when that retry
  /// didn't help: the cursor advances anyway and the lowest unknown version
  /// is remembered in `syncState.missingKeyVersion`, so a `keyVersion: 9999`
  /// injected by a hostile member can't freeze the congregation. If that
  /// version ever does arrive, the next pull resets the cursor and re-pulls
  /// from scratch.
  Future<PullResult> pullOnce(
    String congregationId, {
    bool acceptUnknownKeyVersions = false,
  }) async {
    const empty = PullResult(fetched: 0, applied: 0);
    final keyring = await keyringFor(congregationId);
    if (keyring == null) return empty;

    var state = await (_db.select(_db.syncState)
          ..where((t) => t.congregationId.equals(congregationId)))
        .getSingleOrNull();

    // Recovery: we once gave up on a version and moved the cursor past docs
    // we couldn't read. Now that we hold it, the only way to get them back
    // is to rewind and re-pull the whole history (LWW makes that idempotent).
    final missing = state?.missingKeyVersion;
    if (missing != null && keyring.keys.containsKey(missing)) {
      await _db.into(_db.syncState).insertOnConflictUpdate(
            SyncStateCompanion.insert(
              congregationId: congregationId,
              pullCursor: const Value(null),
              missingKeyVersion: const Value(null),
              updatedAt: DateTime.now().toUtc(),
            ),
          );
      state = null;
    }

    final docs =
        await _transport.pullSince(congregationId, state?.pullCursor);
    if (docs.isEmpty) return empty;

    var applied = 0;
    var skipped = 0;
    final unknownVersions = <int>{};
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
          } on UnknownKeyVersionException catch (e) {
            // TRANSIENT: the blob is fine, we just don't hold that key yet
            // (a rotation elsewhere). Skipping it would be fine; letting the
            // cursor pass it would NOT — we'd never look at this doc again.
            unknownVersions.add(e.keyVersion);
            continue;
          } on ContentDecryptException {
            // PERMANENT: a corrupt or injected blob must never abort the
            // batch or hold the cursor, or one bad doc would wedge this
            // congregation's sync forever (a cheap denial of service for
            // anyone who can write to the collection). Skip and move on.
            skipped++;
            continue;
          }
          await _codec.apply(kind, doc.entityId, payload, doc.hlc);
          applied++;
        }
      }
      // Everything we DID apply stays applied even when the cursor is held:
      // re-pulling the same page is idempotent under LWW.
      if (unknownVersions.isEmpty || acceptUnknownKeyVersions) {
        await _db.into(_db.syncState).insertOnConflictUpdate(
              SyncStateCompanion.insert(
                congregationId: congregationId,
                pullCursor: Value(docs.last.serverTs),
                // Remember the LOWEST version we gave up on: recovering it
                // rewinds the furthest, and re-pulling then rediscovers any
                // higher one still missing.
                missingKeyVersion: Value(_lowestMissing(
                    state?.missingKeyVersion, unknownVersions)),
                updatedAt: DateTime.now().toUtc(),
              ),
            );
      }
    });
    return PullResult(
      fetched: docs.length,
      applied: applied,
      undecryptable: skipped,
      unknownKeyVersions: unknownVersions,
      cursorHeld: unknownVersions.isNotEmpty && !acceptUnknownKeyVersions,
    );
  }

  static int? _lowestMissing(int? remembered, Set<int> seen) {
    final candidates = [?remembered, ...seen];
    return candidates.isEmpty
        ? null
        : candidates.reduce((a, b) => a < b ? a : b);
  }
}
