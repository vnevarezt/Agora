import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sync/link_service.dart';
import '../data/sync/user_key_service.dart';
import 'sync_provider.dart';

/// Where this account/device stands with its E2E sync identity. The user
/// never types a secret: the first device mints the key silently, and any
/// further device is authorised from one that already syncs.
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

/// The account has an identity but this device doesn't hold it → link it
/// from a device that already syncs.
class SyncKeysNeedsLink extends SyncKeysState {
  const SyncKeysNeedsLink();
}

/// Seed present: sealed boxes open, sync can run.
class SyncKeysReady extends SyncKeysState {
  const SyncKeysReady();
}

class SyncKeysError extends SyncKeysState {
  const SyncKeysError(this.messageKey);

  /// 'identityMismatch' | 'badCode' | 'unknown' — localized by the UI.
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
      switch (await service.status()) {
        case UserKeyStatus.notSetUp:
          // Brand-new account: mint the identity with no user interaction —
          // this is what makes sync "just work" after signing in.
          await service.generate();
          await _rememberOwner();
          state = const SyncKeysReady();
        case UserKeyStatus.needsLink:
          state = const SyncKeysNeedsLink();
        case UserKeyStatus.ready:
          await _rememberOwner();
          state = const SyncKeysReady();
          // Retire the pre-4c passphrase envelope now that a device with the
          // seed is running the new code.
          await service.dropLegacyEnvelope();
      }
    } catch (_) {
      state = const SyncKeysError('unknown');
    }
  }

  /// NEW device: open a session and show its code. The caller drives the
  /// wait so it can render progress.
  Future<LinkSession> startLink() async {
    final link = ref.read(linkServiceProvider);
    if (link == null) throw StateError('Cloud sync is unavailable.');
    return link.start();
  }

  /// NEW device: block until the other device answers. Returns false on
  /// timeout. Throws a reason key the UI can localize.
  Future<bool> completeLink(LinkSession session) async {
    final link = ref.read(linkServiceProvider);
    if (link == null) return false;
    try {
      final linked = await link.awaitCompletion(session);
      if (linked) {
        await _rememberOwner();
        await _refresh();
      }
      return linked;
    } on LinkIdentityMismatch {
      state = const SyncKeysError('identityMismatch');
      throw 'identityMismatch';
    } catch (_) {
      throw 'unknown';
    }
  }

  /// EXISTING device: approve a code shown by another device.
  Future<void> approveLink(String code) async {
    final link = ref.read(linkServiceProvider);
    if (link == null) throw 'unknown';
    try {
      await link.approve(code);
    } catch (_) {
      // Bad paste, expired mailbox or no seed here — all actionable as
      // "that code didn't work".
      throw 'badCode';
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
