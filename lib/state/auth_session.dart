import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/db/connection.dart';
import '../data/db/db_key_manager.dart';
import 'cloud_auth.dart';

final dbKeyManagerProvider = Provider<DbKeyManager>((ref) => DbKeyManager());

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
  const SessionLocalLocked(this.profileName);

  final String? profileName;
}

/// Cloud mode with no Firebase session → cloud sign-in screen.
class SessionCloudSignedOut extends SessionState {
  const SessionCloudSignedOut();
}

class SessionUnlocked extends SessionState {
  const SessionUnlocked(this.dekHex, this.mode);

  final String dekHex;
  final AccountMode mode;
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

  AccountMode? _mode;
  String? _profileName;
  StreamSubscription<User?>? _cloudSub;

  @override
  SessionState build() {
    ref.onDispose(() => _cloudSub?.cancel());
    Future.microtask(_init);
    return const SessionLoading();
  }

  DbKeyManager get _keys => ref.read(dbKeyManagerProvider);

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _profileName = prefs.getString(_nameKey);
      _mode = switch (prefs.getString(_modeKey)) {
        'local' => AccountMode.local,
        'cloud' => AccountMode.cloud,
        _ => null,
      };
      switch (_mode) {
        case AccountMode.local:
          state = SessionLocalLocked(_profileName);
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
    state = SessionUnlocked(dek, AccountMode.local);
  }

  /// Migration wizard ([SessionLocalCreate] with migration).
  Future<void> migrate(String name, String password) async {
    final dek = await _keys.migrateLegacy(password);
    await _persistLocalMode(name);
    state = SessionUnlocked(dek, AccountMode.local);
  }

  /// Throws [WrongPasswordException] / [DbKeyException]; the screen shows the
  /// error while the state stays [SessionLocalLocked].
  Future<void> unlock(String password) async {
    state = SessionUnlocked(await _keys.unlock(password), AccountMode.local);
  }

  void lock() => state = SessionLocalLocked(_profileName);

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
      state = SessionUnlocked(
          await _keys.getOrCreateCloudKeyHex(), AccountMode.cloud);
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
    _mode = null;
    _profileName = null;
    state = const SessionFreshChoose();
  }

  Future<void> _persistLocalMode(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, 'local');
    await prefs.setString(_nameKey, name);
    _mode = AccountMode.local;
    _profileName = name;
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
    if (state is SessionUnlocked) return;
    try {
      state = SessionUnlocked(
          await _keys.getOrCreateCloudKeyHex(), AccountMode.cloud);
    } on DbKeyException catch (e) {
      state = SessionKeyError(e.message);
    }
  }
}
