import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sync/user_key_service.dart';
import 'sync_provider.dart';

/// Where this account/device stands with its E2E sync identity. The user
/// never manages a secret: the key is minted on first sign-in and stored in
/// the account, so any device of theirs picks it up automatically.
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

/// The identity is on this device: sync can run.
class SyncKeysReady extends SyncKeysState {
  const SyncKeysReady();
}

/// The account has an identity this device couldn't fetch (offline or a
/// read error). Transient — it resolves on its own.
class SyncKeysStalled extends SyncKeysState {
  const SyncKeysStalled();
}

class SyncKeysError extends SyncKeysState {
  const SyncKeysError(this.messageKey);

  /// 'unknown' — localized by the UI.
  final String messageKey;
}

/// Which account this device's data belongs to (account-switch guard). Also
/// cleared on sign-out, which is why it lives outside the controller.
const syncOwnerUidKey = 'sync_owner_uid';

final syncKeysProvider =
    NotifierProvider<SyncKeysController, SyncKeysState>(SyncKeysController.new);

class SyncKeysController extends Notifier<SyncKeysState> {
  UserKeyService? get _service => ref.read(userKeyServiceProvider);

  @override
  SyncKeysState build() {
    // Rebuild whenever sign-in state flips.
    ref.watch(userKeyServiceProvider);
    Future.microtask(refresh);
    return const SyncKeysLoading();
  }

  /// Makes the identity available on this device — minting it for a new
  /// account, or fetching the account's existing one. No user interaction
  /// either way.
  Future<void> refresh() async {
    final service = _service;
    if (service == null) {
      state = const SyncKeysUnavailable();
      return;
    }
    try {
      if (await service.ensureAvailable()) {
        await _rememberOwner();
        state = const SyncKeysReady();
        // Retire the pre-4c passphrase envelope; nothing reads it now.
        await service.dropLegacyEnvelope();
      } else {
        state = const SyncKeysStalled();
      }
    } catch (_) {
      state = const SyncKeysError('unknown');
    }
  }

  /// Account-switch guard: this device's data belongs to ONE uid (per-uid
  /// databases are deferred). Remembers the owner once an identity exists;
  /// [ownsThisDevice] is false when a DIFFERENT account signed in later, and
  /// SyncController refuses to upload this device's data to it.
  Future<void> _rememberOwner() async {
    final uid = ref.read(syncUidProvider);
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(syncOwnerUidKey, uid);
  }

  Future<bool> ownsThisDevice() async {
    final uid = ref.read(syncUidProvider);
    if (uid == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final owner = prefs.getString(syncOwnerUidKey);
    return owner == null || owner == uid;
  }
}
