import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/connection.dart';
import '../data/db/db_key_manager.dart';
import '../data/device_auth.dart';
import 'cloud_auth.dart';
import 'sync_keys.dart' show syncOwnerUidKey;

final dbKeyManagerProvider = Provider<DbKeyManager>((ref) => DbKeyManager());

/// The device-unlock DEK copy vanished from the keychain. The controller has
/// already switched the preference off; the password is the way back in.
class DeviceUnlockKeyMissing implements Exception {
  const DeviceUnlockKeyMissing();
}

/// How this install authenticates. Chosen once on the Portada; local mode
/// gates the DB with a password-wrapped key, cloud mode gates it with the
/// Firebase session (device key lives in the keychain).
enum AccountMode { local, cloud }

/// Session lifecycle. The DEK that opens the encrypted DB only exists in
/// memory while the state is [SessionUnlocked]; everything that touches the
/// database must live below [AuthGate].
sealed class SessionState {
  const SessionState();
}

class SessionLoading extends SessionState {
  const SessionLoading();
}

/// No mode chosen yet → Portada (create cloud account / sign in / go local).
class SessionFreshChoose extends SessionState {
  const SessionFreshChoose();
}

/// Local profile wizard. [migration] wraps a pre-account plaintext key
/// instead of generating a new one.
class SessionLocalCreate extends SessionState {
  const SessionLocalCreate({required this.migration});

  final bool migration;
}

/// Local mode, waiting for the password.
class SessionLocalLocked extends SessionState {
  const SessionLocalLocked(this.profileName, {this.deviceUnlock = false});

  final String? profileName;

  /// Device unlock (Touch ID / Face ID / fingerprint) is enabled AND this
  /// device supports it: the unlock screen offers it next to the password.
  final bool deviceUnlock;
}

/// Cloud mode with no Firebase session → cloud sign-in screen.
class SessionCloudSignedOut extends SessionState {
  const SessionCloudSignedOut();
}

/// Cloud mode with a live Firebase session but the device-unlock gate armed:
/// only entered when the user enabled it, so the OS prompt is the way in
/// (signing out is the escape hatch).
class SessionCloudLocked extends SessionState {
  const SessionCloudLocked();
}

class SessionUnlocked extends SessionState {
  const SessionUnlocked(this.dekHex, this.mode,
      {this.profileName, this.deviceUnlockEnabled = false});

  final String dekHex;
  final AccountMode mode;

  /// Local profile name (greeting); null in cloud mode for now.
  final String? profileName;

  /// Current value of the device-unlock preference (Settings toggle).
  final bool deviceUnlockEnabled;
}

/// The keychain itself failed (not a wrong password): nothing can proceed.
class SessionKeyError extends SessionState {
  const SessionKeyError(this.message);

  final String message;
}

final authSessionProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState> {
  static const _modeKey = 'account_mode';
  static const _nameKey = 'local_profile_name';
  static const _deviceUnlockKey = 'device_unlock';

  AccountMode? _mode;
  String? _profileName;
  bool _deviceUnlockPref = false;
  bool _deviceAuthSupported = false;
  StreamSubscription<User?>? _cloudSub;

  @override
  SessionState build() {
    ref.onDispose(() => _cloudSub?.cancel());
    Future.microtask(_init);
    return const SessionLoading();
  }

  DbKeyManager get _keys => ref.read(dbKeyManagerProvider);

  DeviceAuth get _deviceAuth => ref.read(deviceAuthProvider);

  /// Device unlock actually usable on this device (preference AND hardware).
  bool get _deviceUnlock => _deviceUnlockPref && _deviceAuthSupported;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _profileName = prefs.getString(_nameKey);
      _deviceUnlockPref = prefs.getBool(_deviceUnlockKey) ?? false;
      // Only probe the hardware when the user opted in: avoids a platform
      // round-trip on every boot for everyone else.
      _deviceAuthSupported =
          _deviceUnlockPref && await _deviceAuth.isSupported();
      _mode = switch (prefs.getString(_modeKey)) {
        'local' => AccountMode.local,
        'cloud' => AccountMode.cloud,
        _ => null,
      };
      switch (_mode) {
        case AccountMode.local:
          state = SessionLocalLocked(_profileName, deviceUnlock: _deviceUnlock);
        case AccountMode.cloud:
          await _startCloudWatch();
        case null:
          state = switch (await _keys.status()) {
            LocalKeyStatus.legacyPlaintext =>
              const SessionLocalCreate(migration: true),
            // Wrapped key without a mode: install predates mode selection.
            LocalKeyStatus.wrapped => SessionLocalLocked(_profileName),
            LocalKeyStatus.none => const SessionFreshChoose(),
          };
      }
    } on DbKeyException catch (e) {
      state = SessionKeyError(e.message);
    } catch (e) {
      // Anything else (prefs/platform) would leave the splash spinning
      // forever; surface it with the retry screen instead.
      state = SessionKeyError('$e');
    }
  }

  Future<void> retryInit() async {
    state = const SessionLoading();
    await _init();
  }

  /// Local mode ([SessionFreshChoose] → create). Throws [DbKeyException].
  Future<void> createLocalProfile(String name, String password) async {
    final dek = await _keys.createAccount(password);
    await _persistLocalMode(name);
    state = SessionUnlocked(dek, AccountMode.local, profileName: _profileName);
  }

  /// Migration wizard ([SessionLocalCreate] with migration).
  Future<void> migrate(String name, String password) async {
    final dek = await _keys.migrateLegacy(password);
    await _persistLocalMode(name);
    state = SessionUnlocked(dek, AccountMode.local, profileName: _profileName);
  }

  /// Throws [WrongPasswordException] / [DbKeyException]; the screen shows the
  /// error while the state stays [SessionLocalLocked].
  Future<void> unlock(String password) async {
    state = SessionUnlocked(await _keys.unlock(password), AccountMode.local,
        profileName: _profileName, deviceUnlockEnabled: _deviceUnlock);
  }

  /// OS prompt → unlocked, in either mode. False when the user cancelled or
  /// failed the prompt (no state change; the password path stays available).
  /// Throws [DeviceUnlockKeyMissing] if the local key copy vanished: the
  /// preference is switched off so the screen falls back to password-only.
  Future<bool> unlockWithDeviceAuth(String reason) async {
    if (!_deviceUnlock) return false;
    if (!await _deviceAuth.authenticate(reason)) return false;
    if (_mode == AccountMode.cloud) {
      state = SessionUnlocked(
          await _keys.getOrCreateCloudKeyHex(), AccountMode.cloud,
          deviceUnlockEnabled: true);
      return true;
    }
    final dek = await _keys.readDeviceUnlockKey();
    if (dek == null) {
      await _persistDeviceUnlockPref(false);
      state = SessionLocalLocked(_profileName);
      throw const DeviceUnlockKeyMissing();
    }
    state = SessionUnlocked(dek, AccountMode.local,
        profileName: _profileName, deviceUnlockEnabled: true);
    return true;
  }

  void lock() => state = switch (_mode) {
        AccountMode.cloud => const SessionCloudLocked(),
        _ => SessionLocalLocked(_profileName, deviceUnlock: _deviceUnlock),
      };

  /// Settings toggle, both modes; requires an unlocked session. Enabling asks
  /// for the OS prompt right away — proves the user can actually pass it
  /// before the password shortcut exists (and in local mode the DEK copy is
  /// only written after that proof). Returns the resulting value.
  Future<bool> setDeviceUnlock(bool enable, String reason) async {
    final s = state;
    if (s is! SessionUnlocked) return _deviceUnlockPref;
    if (enable) {
      if (!await _deviceAuth.authenticate(reason)) return false;
      // Passing the prompt is the hardware probe: no separate isSupported().
      _deviceAuthSupported = true;
      if (s.mode == AccountMode.local) await _keys.enableDeviceUnlock(s.dekHex);
    } else {
      await _keys.disableDeviceUnlock();
    }
    await _persistDeviceUnlockPref(enable);
    state = SessionUnlocked(s.dekHex, s.mode,
        profileName: s.profileName, deviceUnlockEnabled: enable);
    return enable;
  }

  /// Re-wraps the DEK; the session stays unlocked. Throws
  /// [WrongPasswordException] when [current] is wrong.
  Future<void> changePassword(String current, String next) =>
      _keys.changePassword(current, next);

  /// Called after a successful Firebase sign-in when the cloud gate is the
  /// entry (Portada or [SessionCloudSignedOut]); Settings sign-ins for
  /// local-mode users never reach this.
  Future<void> completeCloudSignIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modeKey, 'cloud');
      _mode = AccountMode.cloud;
      // Fresh sign-in counts as proving identity: no device-unlock gate here.
      state = SessionUnlocked(
          await _keys.getOrCreateCloudKeyHex(), AccountMode.cloud,
          deviceUnlockEnabled: _deviceUnlock);
      await _startCloudWatch();
    } on DbKeyException catch (e) {
      state = SessionKeyError(e.message);
    } catch (e) {
      state = SessionKeyError('$e');
    }
  }

  /// The data is unrecoverable by design: delete the DB file plus every key
  /// and start over from the Portada.
  Future<void> resetAllData() async {
    await _cloudSub?.cancel();
    _cloudSub = null;
    // Best-effort: don't leave a ghost Firebase session behind the fresh
    // Portada (also covers local-mode users signed in from Settings).
    try {
      await (await ref.read(cloudAuthProvider.future))?.signOut();
    } catch (_) {}
    final file = await databaseFile();
    if (await file.exists()) await file.delete();
    await _keys.destroyAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_modeKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_deviceUnlockKey);
    // The sync identity is gone with the keychain: don't leave this device
    // claimed by an account it can no longer prove.
    await prefs.remove(syncOwnerUidKey);
    _mode = null;
    _profileName = null;
    _deviceUnlockPref = false;
    state = const SessionFreshChoose();
  }

  Future<void> _persistLocalMode(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, 'local');
    await prefs.setString(_nameKey, name);
    _mode = AccountMode.local;
    _profileName = name;
  }

  Future<void> _persistDeviceUnlockPref(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_deviceUnlockKey, enable);
    _deviceUnlockPref = enable;
  }

  /// Cloud mode routing: the Firebase session is the gate. authStateChanges
  /// emits the current user on listen, so this also resolves the boot state.
  Future<void> _startCloudWatch() async {
    final app = await ref.read(firebaseAppProvider.future);
    if (app == null) {
      state = const SessionCloudSignedOut();
      return;
    }
    await _cloudSub?.cancel();
    _cloudSub =
        FirebaseAuth.instanceFor(app: app).authStateChanges().listen(_onCloudUser);
  }

  Future<void> _onCloudUser(User? user) async {
    if (_mode != AccountMode.cloud) return;
    if (user == null) {
      state = const SessionCloudSignedOut();
      return;
    }
    if (state is SessionUnlocked || state is SessionCloudLocked) return;
    if (_deviceUnlock) {
      // Session restored from disk (app relaunch): arm the gate.
      state = const SessionCloudLocked();
      return;
    }
    try {
      state = SessionUnlocked(
          await _keys.getOrCreateCloudKeyHex(), AccountMode.cloud);
    } on DbKeyException catch (e) {
      state = SessionKeyError(e.message);
    }
  }
}
