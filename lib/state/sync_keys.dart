import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/crypto/passphrase_envelope.dart';
import '../data/sync/user_key_service.dart';
import 'sync_provider.dart';

/// Where this account/device stands with the E2E sync passphrase. Minimal
/// intrusion: after cloud sign-in sync is OFF until the user creates or
/// enters the passphrase here (Settings → Sync card). Never touches the
/// local-DB session (AuthGate).
sealed class SyncKeysState {
  const SyncKeysState();
}

/// Cloud unconfigured or signed out: nothing to do.
class SyncKeysUnavailable extends SyncKeysState {
  const SyncKeysUnavailable();
}

class SyncKeysLoading extends SyncKeysState {
  const SyncKeysLoading();
}

/// Signed in, no `users/{uid}` yet → create-passphrase flow.
class SyncKeysNotSetUp extends SyncKeysState {
  const SyncKeysNotSetUp();
}

/// Keys exist in the cloud but this device holds no seed → enter passphrase.
class SyncKeysLocked extends SyncKeysState {
  const SyncKeysLocked();
}

/// Seed cached: sealed boxes open, sync can run.
class SyncKeysReady extends SyncKeysState {
  const SyncKeysReady();
}

class SyncKeysError extends SyncKeysState {
  const SyncKeysError(this.messageKey);

  /// 'wrongPassphrase' | 'unknown' — the UI maps it to a localized string.
  final String messageKey;
}

final syncKeysProvider =
    NotifierProvider<SyncKeysController, SyncKeysState>(SyncKeysController.new);

class SyncKeysController extends Notifier<SyncKeysState> {
  static const _ownerUidKey = 'sync_owner_uid';

  UserKeyService? get _service => ref.read(userKeyServiceProvider);

  @override
  SyncKeysState build() {
    // Rebuild whenever sign-in state flips.
    ref.watch(userKeyServiceProvider);
    Future.microtask(_refresh);
    return const SyncKeysLoading();
  }

  Future<void> _refresh() async {
    final service = _service;
    if (service == null) {
      state = const SyncKeysUnavailable();
      return;
    }
    try {
      state = switch (await service.status()) {
        UserKeyStatus.notSetUp => const SyncKeysNotSetUp(),
        UserKeyStatus.locked => const SyncKeysLocked(),
        UserKeyStatus.ready => const SyncKeysReady(),
      };
    } catch (_) {
      state = const SyncKeysError('unknown');
    }
  }

  /// First-time setup on this account. Throws a reason key on failure.
  Future<bool> createPassphrase(String passphrase) =>
      _run(() async {
        await _service!.create(passphrase);
        await _rememberOwner();
      });

  /// New device / relocked account. Throws a reason key on failure.
  Future<bool> enterPassphrase(String passphrase) =>
      _run(() async {
        await _service!.unlock(passphrase);
        await _rememberOwner();
      });

  Future<bool> changePassphrase(String current, String next) =>
      _run(() => _service!.changePassphrase(current, next));

  /// Returns true on success. On failure sets an error state AND rethrows a
  /// short reason key so the calling screen can show it inline and let the
  /// user retry without losing the form.
  Future<bool> _run(Future<void> Function() op) async {
    state = const SyncKeysLoading();
    try {
      await op();
      await _refresh();
      return true;
    } on WrongPassphraseException {
      await _refresh(); // back to Locked / NotSetUp
      throw 'wrongPassphrase';
    } catch (_) {
      state = const SyncKeysError('unknown');
      throw 'unknown';
    }
  }

  /// Account-switch guard: this device's data belongs to ONE uid (per-uid
  /// databases are deferred). Remembers the owner on first setup;
  /// [ownsThisDevice] is false when a DIFFERENT account signed in later, and
  /// SyncController refuses to upload this device's data to it.
  Future<void> _rememberOwner() async {
    final uid = ref.read(syncUidProvider);
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_ownerUidKey, uid);
  }

  Future<bool> ownsThisDevice() async {
    final uid = ref.read(syncUidProvider);
    if (uid == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final owner = prefs.getString(_ownerUidKey);
    return owner == null || owner == uid;
  }
}
