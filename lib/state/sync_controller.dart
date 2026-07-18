import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/widgets.dart' show AppLifecycleListener, AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sync/firestore_transport.dart';
import '../data/sync/sync_engine.dart';
import 'db_provider.dart';
import 'sync_provider.dart';

/// What the sync engine is doing right now (drives the Settings status row
/// and, in 4b-3, the shell badge).
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

/// Drives the engine: a debounced push whenever the outbox changes, and a
/// pull on start / resume / after-push / manual. No Firestore snapshot
/// listeners in this cut (4b-3 adds a cheap realtime signal); the pull query
/// stays the single read path.
class SyncController extends Notifier<SyncStatus> {
  static const _pushDebounce = Duration(seconds: 2);
  static const _periodicPull = Duration(minutes: 5);

  Timer? _pushTimer;
  Timer? _pullTimer;
  StreamSubscription<void>? _outboxSub;
  AppLifecycleListener? _lifecycle;
  bool _running = false;

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
    Future.microtask(_arm);
    return const SyncStatus(phase: SyncPhase.idle);
  }

  void _teardown() {
    _pushTimer?.cancel();
    _pullTimer?.cancel();
    _outboxSub?.cancel();
    _lifecycle?.dispose();
    _pushTimer = _pullTimer = null;
    _outboxSub = null;
    _lifecycle = null;
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
    _lifecycle = AppLifecycleListener(onStateChange: (s) {
      if (s == AppLifecycleState.resumed) pullAll();
    });
    _pullTimer = Timer.periodic(_periodicPull, (_) => pullAll());
    // Initial reconcile.
    pullAll();
  }

  void _schedulePush() {
    _pushTimer?.cancel();
    _pushTimer = Timer(_pushDebounce, syncNow);
  }

  /// Manual "Sincronizar ahora": push then pull, surfacing status.
  Future<void> syncNow() async {
    if (_running || _engine == null) {
      debugPrint('sync: syncNow skipped '
          '(running=$_running, engine=${_engine != null})');
      return;
    }
    _running = true;
    state = state.copyWith(phase: SyncPhase.syncing, clearError: true);
    try {
      final pushed = await _engine!.pushOnce();
      debugPrint('sync: syncNow pushed $pushed doc(s)');
      await _pullAllInner();
      state = state.copyWith(
          phase: SyncPhase.idle, lastSyncAt: DateTime.now(), clearError: true);
    } on SyncTransportException catch (e) {
      _onTransportError(e);
    } catch (_) {
      state = state.copyWith(phase: SyncPhase.error, errorKey: 'unknown');
    } finally {
      _running = false;
    }
  }

  /// Pull every congregation this user belongs to (covers freshly joined
  /// ones whose local rows don't exist yet — the pulled congregation item
  /// creates them).
  Future<void> pullAll() async {
    if (_running || _engine == null) return;
    _running = true;
    state = state.copyWith(phase: SyncPhase.syncing, clearError: true);
    try {
      await _pullAllInner();
      state = state.copyWith(
          phase: SyncPhase.idle, lastSyncAt: DateTime.now(), clearError: true);
    } on SyncTransportException catch (e) {
      _onTransportError(e);
    } catch (_) {
      state = state.copyWith(phase: SyncPhase.error, errorKey: 'unknown');
    } finally {
      _running = false;
    }
  }

  Future<void> _pullAllInner() async {
    final engine = _engine;
    if (engine == null) return;
    final memberships = ref.read(myMembershipsProvider).value ?? const [];
    for (final m in memberships) {
      // Drain pages for this congregation.
      PullResult page;
      do {
        page = await engine.pullOnce(m.congregationId);
      } while (page.fetched >= FirestoreTransport.pageSize);
    }
  }

  void _onTransportError(SyncTransportException e) {
    switch (e.kind) {
      case SyncTransportErrorKind.offline:
        state = state.copyWith(phase: SyncPhase.offline, errorKey: 'offline');
      case SyncTransportErrorKind.permissionDenied:
        // Revoked from a congregation: keep local data, surface it. The CCK
        // cache drop + per-cid stop lands with revocation handling in 4b-2.
        state = state.copyWith(
            phase: SyncPhase.error, errorKey: 'permissionDenied');
      case SyncTransportErrorKind.unknown:
        state = state.copyWith(phase: SyncPhase.error, errorKey: 'unknown');
    }
  }
}
