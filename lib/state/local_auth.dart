import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/connection.dart';
import '../data/db/db_key_manager.dart';

final dbKeyManagerProvider = Provider<DbKeyManager>((ref) => DbKeyManager());

/// Local session lifecycle. The DEK that opens the encrypted DB only exists
/// in memory while the state is [LocalAuthUnlocked]; everything that touches
/// the database must live below [AuthGate].
sealed class LocalAuthState {
  const LocalAuthState();
}

/// Reading the keychain to decide the entry screen.
class LocalAuthLoading extends LocalAuthState {
  const LocalAuthLoading();
}

/// Fresh install: no key material → create-account wizard.
class LocalAuthFreshSetup extends LocalAuthState {
  const LocalAuthFreshSetup();
}

/// Pre-account install detected (plaintext DEK): force the wizard that wraps
/// the existing key with a new password.
class LocalAuthMigration extends LocalAuthState {
  const LocalAuthMigration();
}

/// Account exists; waiting for the password.
class LocalAuthLocked extends LocalAuthState {
  const LocalAuthLocked();
}

/// Session open. [dekHex] feeds `openEncryptedExecutor`.
class LocalAuthUnlocked extends LocalAuthState {
  const LocalAuthUnlocked(this.dekHex);

  final String dekHex;
}

/// The keychain itself failed (not a wrong password): nothing can proceed.
class LocalAuthKeyError extends LocalAuthState {
  const LocalAuthKeyError(this.message);

  final String message;
}

final localAuthProvider =
    NotifierProvider<LocalAuthController, LocalAuthState>(
        LocalAuthController.new);

class LocalAuthController extends Notifier<LocalAuthState> {
  @override
  LocalAuthState build() {
    Future.microtask(_init);
    return const LocalAuthLoading();
  }

  DbKeyManager get _keys => ref.read(dbKeyManagerProvider);

  Future<void> _init() async {
    try {
      state = switch (await _keys.status()) {
        LocalKeyStatus.none => const LocalAuthFreshSetup(),
        LocalKeyStatus.legacyPlaintext => const LocalAuthMigration(),
        LocalKeyStatus.wrapped => const LocalAuthLocked(),
      };
    } on DbKeyException catch (e) {
      state = LocalAuthKeyError(e.message);
    }
  }

  Future<void> retryInit() async {
    state = const LocalAuthLoading();
    await _init();
  }

  /// Throws [WrongPasswordException] / [DbKeyException]; the screen shows the
  /// error while the state stays [LocalAuthLocked].
  Future<void> unlock(String password) async {
    state = LocalAuthUnlocked(await _keys.unlock(password));
  }

  /// Fresh-install wizard ([LocalAuthFreshSetup]).
  Future<void> createAccount(String password) async {
    state = LocalAuthUnlocked(await _keys.createAccount(password));
  }

  /// Migration wizard ([LocalAuthMigration]).
  Future<void> migrate(String password) async {
    state = LocalAuthUnlocked(await _keys.migrateLegacy(password));
  }

  void lock() => state = const LocalAuthLocked();

  /// Re-wraps the DEK; the session stays unlocked. Throws
  /// [WrongPasswordException] when [current] is wrong.
  Future<void> changePassword(String current, String next) =>
      _keys.changePassword(current, next);

  /// "Forgot password": the data is unrecoverable by design, so the only way
  /// forward is deleting the DB file plus every key and starting over.
  Future<void> resetAllData() async {
    final file = await databaseFile();
    if (await file.exists()) await file.delete();
    await _keys.destroyAll();
    state = const LocalAuthFreshSetup();
  }
}
