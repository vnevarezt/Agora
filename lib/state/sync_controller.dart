import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart'
    show AppLifecycleListener, AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync/firestore_transport.dart';
import '../data/sync/pull_policy.dart';
import '../data/sync/sync_engine.dart';
import 'app_settings.dart';
import 'dashboard_provider.dart';
import 'db_provider.dart';
import 'editor_session.dart';
import 'sync_keys.dart';
import 'sync_provider.dart';
import 'ui_state.dart';

/// What the sync engine is doing right now (drives the Settings status row
/// and the dashboard's exceptional-state indicator).
enum SyncPhase { disabled, idle, syncing, offline, error }

class SyncStatus {
  const SyncStatus({
    this.phase = SyncPhase.disabled,
    this.lastSyncAt,
    this.pendingOutbox = 0,
    this.errorKey,
  });

  final SyncPhase phase;
  final DateTime? lastSyncAt;
  final int pendingOutbox;

  /// 'permissionDenied' | 'offline' | 'unknown' — localized by the UI.
  final String? errorKey;

  SyncStatus copyWith({
    SyncPhase? phase,
    DateTime? lastSyncAt,
    int? pendingOutbox,
    String? errorKey,
    bool clearError = false,
  }) =>
      SyncStatus(
        phase: phase ?? this.phase,
        lastSyncAt: lastSyncAt ?? this.lastSyncAt,
        pendingOutbox: pendingOutbox ?? this.pendingOutbox,
        errorKey: clearError ? null : (errorKey ?? this.errorKey),
      );
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncStatus>(SyncController.new);

/// Drives the engine so the user never has to (docs/PHASE4_CLOUD_SYNC.md,
/// 4b-3):
///
/// - Push: debounced on outbox changes, plus on reconnect, on app resume and
///   with exponential backoff after failures. The debounce is bypassed when
///   losing it would lose data: leaving the editor, and the app going to the
///   background or being asked to quit — the outbox drains as soon as
///   physically possible.
/// - Pull: NO polling. One tiny heartbeat listener per congregation
///   (`meta/activity`) tells us THAT something changed and in WHICH scope;
///   [decidePull] pulls immediately when it affects what's on screen and
///   defers the rest (deferred pulls download only final states). Idle
///   costs zero reads.
class SyncController extends Notifier<SyncStatus> {
  static const _pushDebounce = Duration(seconds: 2);
  static const _lazyDelay = Duration(minutes: 3);
  static const _retryDelays = [
    Duration(seconds: 30),
    Duration(minutes: 2),
    Duration(minutes: 8),
  ];

  Timer? _pushTimer;
  Timer? _lazyTimer;
  Timer? _retryTimer;
  int _failures = 0;
  StreamSubscription<void>? _outboxSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  AppLifecycleListener? _lifecycle;
  final _heartbeatSubs = <String, StreamSubscription<void>>{};
  final _staleCids = <String>{};

  /// Congregations this session already tried to put in the cloud.
  final _autoEnabled = <String>{};
  bool _autoEnabling = false;
  bool _pushing = false;
  bool _pulling = false;

  SyncEngine? get _engine => ref.read(syncEngineProvider);

  @override
  SyncStatus build() {
    // Re-arm whenever the engine's availability flips (sign-in, keys ready).
    final engine = ref.watch(syncEngineProvider);
    ref.onDispose(_teardown);

    if (engine == null) {
      _teardown();
      return const SyncStatus(phase: SyncPhase.disabled);
    }

    // Membership changes re-target the heartbeat listeners; opening a view
    // flushes its deferred pulls (the lazy window exists to coalesce, not to
    // let the user see stale data they're looking at).
    ref.listen(myMembershipsProvider, (_, next) {
      _attachHeartbeats({for (final m in next.value ?? []) m.congregationId});
      _autoEnable();
    });
    // A congregation created locally must reach the cloud on its own.
    ref.listen(congregationsProvider, (_, _) => _autoEnable());
    ref.listen(editorProjectProvider, (prev, next) {
      if (next != null) {
        _flushStale();
      } else if (prev != null) {
        // Left the editor: push its edits now instead of waiting out the
        // debounce, so leaving the program screen is a sync checkpoint.
        _flushPushNow();
      }
    });
    ref.listen(appSectionProvider, (_, _) => _flushStale());

    Future.microtask(_arm);
    return const SyncStatus(phase: SyncPhase.idle);
  }

  void _teardown() {
    _pushTimer?.cancel();
    _lazyTimer?.cancel();
    _retryTimer?.cancel();
    _outboxSub?.cancel();
    _connectivitySub?.cancel();
    _lifecycle?.dispose();
    for (final sub in _heartbeatSubs.values) {
      sub.cancel();
    }
    _heartbeatSubs.clear();
    _staleCids.clear();
    _autoEnabled.clear();
    _pushTimer = _lazyTimer = _retryTimer = null;
    _outboxSub = null;
    _connectivitySub = null;
    _lifecycle = null;
    _failures = 0;
  }

  void _arm() {
    final db = ref.read(dbProvider);
    // Debounced push on every outbox change + a live pending count.
    _outboxSub =
        db.customSelect('SELECT COUNT(*) AS c FROM outbox').watch().listen(
      (rows) {
        final count = rows.first.read<int>('c');
        state = state.copyWith(pendingOutbox: count);
        if (count > 0) _schedulePush();
      },
    );
    // Regained network or foregrounded: drain whatever queued meanwhile.
    // (Pulls need no hook here — the heartbeat listeners reconnect on their
    // own and redeliver anything missed.)
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (!online) return;
      // A failed auto-enable was most likely the network: let it retry.
      _autoEnabled.clear();
      _autoEnable();
      if (state.pendingOutbox > 0) _schedulePush();
    });
    _lifecycle = AppLifecycleListener(
      onStateChange: (s) {
        switch (s) {
          case AppLifecycleState.resumed:
            if (state.pendingOutbox > 0) _schedulePush();
          case AppLifecycleState.hidden:
          case AppLifecycleState.paused:
            // Leaving the foreground: the OS may suspend or kill us before
            // the debounce fires, stranding a queued edit until the next
            // launch (or forever, if the app is reinstalled). Flush now.
            _flushPushNow();
          case AppLifecycleState.inactive:
          case AppLifecycleState.detached:
            break;
        }
      },
      // Desktop quit: hold termination just long enough to drain the outbox,
      // so a change made seconds before closing still reaches the cloud.
      onExitRequested: () async {
        if (state.pendingOutbox > 0) {
          try {
            await _push();
          } catch (_) {}
        }
        return AppExitResponse.exit;
      },
    );
    _attachHeartbeats({
      for (final m in ref.read(myMembershipsProvider).value ?? [])
        m.congregationId,
    });
    _autoEnable();
  }

  // ---- auto-enable ---------------------------------------------------------

  /// Every local congregation belongs in the cloud once the sync keys are
  /// ready — enabling is not a decision we make the user take per
  /// congregation. Mints the CCK, creates the space and seeds the subtree;
  /// the outbox watch pushes it. Attempts are remembered for the session so
  /// a permanent failure (e.g. a space someone else owns) can't loop;
  /// regaining connectivity clears them for a retry.
  Future<void> _autoEnable() async {
    if (_autoEnabling || ref.read(cckServiceProvider) == null) return;
    // This device's local data belongs to ONE account (per-uid databases are
    // deferred): never upload it to a different one that signed in later.
    if (!await ref.read(syncKeysProvider.notifier).ownsThisDevice()) return;
    final memberships = ref.read(myMembershipsProvider);
    // Until memberships load we can't tell which are missing.
    if (memberships.isLoading || memberships.hasError) return;
    final inCloud = {
      for (final m in memberships.value ?? []) m.congregationId,
    };
    final pending = [
      for (final c in ref.read(congregationsProvider))
        if (!inCloud.contains(c.id) && !_autoEnabled.contains(c.id)) c.id,
    ];
    if (pending.isEmpty) return;

    _autoEnabling = true;
    try {
      for (final cid in pending) {
        _autoEnabled.add(cid);
        try {
          await ref.read(enableCongregationSyncProvider)(cid);
        } catch (_) {
          // Offline, or a space this user can't found: retry on reconnect.
        }
      }
    } finally {
      _autoEnabling = false;
    }
  }

  // ---- heartbeat listeners -------------------------------------------------

  void _attachHeartbeats(Set<String> cids) {
    final fs = ref.read(firestoreProvider);
    if (fs == null) return;
    for (final cid in _heartbeatSubs.keys.toList()) {
      if (!cids.contains(cid)) {
        _heartbeatSubs.remove(cid)?.cancel();
        _staleCids.remove(cid);
      }
    }
    for (final cid in cids) {
      _heartbeatSubs.putIfAbsent(
        cid,
        () => fs
            .collection('congregations')
            .doc(cid)
            .collection('meta')
            .doc('activity')
            .snapshots()
            .listen((snap) => _onHeartbeat(cid, snap), onError: (_) {
          // Listener errors (revocation, network) are non-fatal: pushes and
          // manual sync surface their own status.
        }),
      );
    }
  }

  Future<void> _onHeartbeat(
    String cid,
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) async {
    final data = snap.data();
    final scopes = <String, String>{
      for (final MapEntry(:key, :value)
          in ((data?['scopes'] as Map?) ?? const {}).entries)
        if (value is Timestamp) key as String: encodeServerTs(value),
    };
    final urgency = decidePull(
      scopes: scopes,
      cursor: await _cursorOf(cid),
      openProjectId: ref.read(editorProjectProvider),
      participantsVisible:
          ref.read(appSectionProvider) == AppSection.participants,
      fromOwnDevice: data?['srcDevice'] == deviceId(),
      heartbeatExists: snap.exists,
    );
    switch (urgency) {
      case PullUrgency.none:
        // Nothing newer than our cursor IS the confirmation that we're up to
        // date — with no polling, this is the only thing that says so.
        _onSuccess();
      case PullUrgency.immediate:
        await _pull({cid});
      case PullUrgency.lazy:
        _staleCids.add(cid);
        _lazyTimer ??= Timer(_lazyDelay, () {
          _lazyTimer = null;
          _flushStale();
        });
    }
  }

  Future<String?> _cursorOf(String cid) async {
    final row = await (ref.read(dbProvider).select(ref.read(dbProvider).syncState)
          ..where((t) => t.congregationId.equals(cid)))
        .getSingleOrNull();
    return row?.pullCursor;
  }

  void _flushStale() {
    if (_staleCids.isEmpty) return;
    _pull(Set.of(_staleCids));
  }

  // ---- push ----------------------------------------------------------------

  void _schedulePush() {
    _pushTimer?.cancel();
    _pushTimer = Timer(_pushDebounce, _push);
  }

  /// Bypass the debounce and push immediately when there is anything queued —
  /// used on lifecycle transitions and when leaving the editor, where waiting
  /// out the debounce risks losing the edit.
  void _flushPushNow() {
    if (state.pendingOutbox == 0) return;
    _pushTimer?.cancel();
    _pushTimer = null;
    unawaited(_push());
  }

  Future<void> _push() async {
    final engine = _engine;
    if (_pushing || engine == null) return;
    _pushing = true;
    state = state.copyWith(phase: SyncPhase.syncing, clearError: true);
    try {
      await engine.pushOnce();
      _onSuccess();
    } on SyncTransportException catch (e) {
      _onTransportError(e);
    } catch (_) {
      state = state.copyWith(phase: SyncPhase.error, errorKey: 'unknown');
    } finally {
      _pushing = false;
    }
  }

  // ---- pull ----------------------------------------------------------------

  Future<void> _pull(Set<String> cids) async {
    final engine = _engine;
    if (_pulling || engine == null) return;
    _pulling = true;
    state = state.copyWith(phase: SyncPhase.syncing, clearError: true);
    var failed = false;
    for (final cid in cids) {
      try {
        await _drain(engine, cid);
        _staleCids.remove(cid);
      } on SyncTransportException catch (e) {
        failed = true;
        // A failing congregation must not starve the rest.
        if (e.kind == SyncTransportErrorKind.permissionDenied) {
          // Revoked: keep local data, stop retrying this one.
          _staleCids.remove(cid);
        }
        _onTransportError(e);
      } catch (_) {
        failed = true;
        state = state.copyWith(phase: SyncPhase.error, errorKey: 'unknown');
      }
    }
    if (!failed) _onSuccess();
    _pulling = false;
  }

  /// Pages through one congregation until it runs dry.
  ///
  /// A page carrying a key version we don't hold does NOT advance the cursor
  /// (see [SyncEngine.pullOnce]) — the engine hands it back so we can fetch
  /// the rotated key and retry the SAME page. Refreshing off
  /// `Membership.keyVersion` instead would not work: that snapshot and the
  /// heartbeat are two independent streams with no ordering between them, so
  /// a heartbeat can fire the pull that burns the cursor before the
  /// membership update ever arrives.
  Future<void> _drain(SyncEngine engine, String cid) async {
    PullResult page;
    do {
      page = await engine.pullOnce(cid);
      if (page.cursorHeld) {
        await ref.read(cckServiceProvider)?.refresh(cid);
        page = await engine.pullOnce(cid);
        if (page.cursorHeld) {
          // Still unknown after fetching the newest keyring: either a writer
          // used a version we will never receive, or a hostile member
          // injected one. Holding the cursor forever would be exactly the
          // denial of service we already closed once, so let it past — the
          // version is remembered, and if it ever does arrive the next pull
          // rewinds and re-reads everything we skipped.
          page = await engine.pullOnce(cid, acceptUnknownKeyVersions: true);
        }
      }
    } while (page.fetched >= FirestoreTransport.pageSize);
  }

  // ---- outcomes ------------------------------------------------------------

  void _onSuccess() {
    _failures = 0;
    _retryTimer?.cancel();
    _retryTimer = null;
    state = state.copyWith(
        phase: SyncPhase.idle, lastSyncAt: DateTime.now(), clearError: true);
  }

  void _onTransportError(SyncTransportException e) {
    state = switch (e.kind) {
      SyncTransportErrorKind.offline =>
        state.copyWith(phase: SyncPhase.offline, errorKey: 'offline'),
      SyncTransportErrorKind.permissionDenied =>
        state.copyWith(phase: SyncPhase.error, errorKey: 'permissionDenied'),
      SyncTransportErrorKind.unknown =>
        state.copyWith(phase: SyncPhase.error, errorKey: 'unknown'),
    };
    _scheduleRetry();
  }

  /// 30 s → 2 min → 8 min, reset on any success. Retries both directions:
  /// the queued outbox and whatever went stale meanwhile.
  void _scheduleRetry() {
    if (_retryTimer != null) return;
    final delay =
        _retryDelays[_failures.clamp(0, _retryDelays.length - 1)];
    _failures++;
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      if (state.pendingOutbox > 0) _push();
      _flushStale();
    });
  }

  /// Manual "Sincronizar ahora" (Settings escape hatch): push everything and
  /// pull every membership, stale or not.
  Future<void> syncNow() async {
    await _push();
    await _pull({
      for (final m in ref.read(myMembershipsProvider).value ?? [])
        m.congregationId,
    });
  }
}
