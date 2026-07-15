import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../cloud_secrets.dart';
import '../firebase_options.dart';
import '../i18n/strings.g.dart';

/// Optional cloud identity (Firebase Auth). The app is local-first by
/// construction: nothing here runs in main(), a placeholder or missing config
/// simply disables the cloud, and no local feature may ever depend on
/// Firebase being available. Cloud sign-in does NOT unlock the local DB.

/// Typed error the UI maps to slang keys.
enum CloudAuthErrorCode {
  invalidEmail,
  userNotFound,
  wrongPassword,
  emailInUse,
  weakPassword,
  network,
  canceled,
  unknown,
}

class CloudAuthException implements Exception {
  const CloudAuthException(this.code, [this.detail]);

  final CloudAuthErrorCode code;
  final String? detail;

  @override
  String toString() => 'CloudAuthException($code${detail == null ? '' : ': $detail'})';
}

/// null = cloud disabled (placeholder config, unsupported platform, or init
/// failure — e.g. firebase_auth's beta Windows support misbehaving).
final firebaseAppProvider = FutureProvider<FirebaseApp?>((ref) async {
  final FirebaseOptions options;
  try {
    options = DefaultFirebaseOptions.currentPlatform;
  } on UnsupportedError {
    return null;
  }
  if (options.apiKey.startsWith('REPLACE')) return null;
  try {
    return await Firebase.initializeApp(options: options);
  } catch (e) {
    debugPrint('Firebase init failed, cloud disabled: $e');
    return null;
  }
});

final firebaseAvailableProvider = Provider<bool>(
    (ref) => ref.watch(firebaseAppProvider).value != null);

/// Whether cloud sign-in can actually work on this install. FirebaseAuth and
/// GoogleSignIn persist sessions in the data-protection keychain, which on
/// macOS needs a provisioning profile (paid Apple team); dev builds signed
/// without one fail every sign-in with keychain errors, so cloud mode hides
/// itself. The probe passes automatically once the app is signed properly.
final cloudAuthSupportedProvider = FutureProvider<bool>((ref) async {
  // Only the keychain probe hides cloud mode. A missing/placeholder Firebase
  // config does NOT: the UI is always shown and the attempt explains itself
  // (see CloudAuthForm), which also keeps dev installs honest.
  if (defaultTargetPlatform != TargetPlatform.macOS) return true;
  const probe = FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: true),
  );
  try {
    await probe.write(key: 'jw_program.dpk_probe', value: '1');
    await probe.delete(key: 'jw_program.dpk_probe');
    return true;
  } catch (_) {
    return false;
  }
});

/// Signed-in Firebase user (null while signed out or when cloud is disabled).
final cloudUserProvider = StreamProvider<User?>((ref) {
  final app = ref.watch(firebaseAppProvider).value;
  if (app == null) return Stream<User?>.value(null);
  return FirebaseAuth.instanceFor(app: app).authStateChanges();
});

/// Google button availability: needs the cloud, a supported platform
/// (no Windows implementation; macOS needs provisioned signing the app
/// doesn't have yet) and, on Android, the OAuth web client ID from
/// cloud_secrets.dart.
final googleSignInAvailableProvider = Provider<bool>((ref) {
  if (!ref.watch(firebaseAvailableProvider)) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => googleServerClientId.isNotEmpty,
    TargetPlatform.iOS => true,
    _ => false,
  };
});

/// null once init settles with the cloud disabled. Await `.future` before
/// acting so a tap during initialization waits instead of concluding the
/// cloud is missing.
final cloudAuthProvider = FutureProvider<CloudAuthService?>((ref) async {
  final app = await ref.watch(firebaseAppProvider.future);
  if (app == null) return null;
  return CloudAuthService(FirebaseAuth.instanceFor(app: app));
});

class CloudAuthService {
  CloudAuthService(this._auth);

  final FirebaseAuth _auth;

  /// google_sign_in v7 requires a single initialize() per process.
  static bool _googleInitialized = false;

  /// Firebase-sent emails (reset, verification) follow the app language.
  /// Best-effort: a failure must never block the auth action itself.
  Future<void> _syncEmailLanguage() async {
    try {
      await _auth.setLanguageCode(LocaleSettings.currentLocale.languageCode);
    } catch (_) {}
  }

  Future<void> registerWithEmail(String email, String password,
          {String? displayName}) =>
      _mapAuthErrors(() async {
        await _syncEmailLanguage();
        final cred = await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        if (displayName != null && displayName.isNotEmpty) {
          await cred.user?.updateDisplayName(displayName);
        }
        // Informative only (access is never gated on it), so a failure to
        // send must not fail the registration.
        try {
          await cred.user?.sendEmailVerification();
        } catch (_) {}
      });

  Future<void> signInWithEmail(String email, String password) =>
      _mapAuthErrors(() =>
          _auth.signInWithEmailAndPassword(email: email, password: password));

  Future<void> sendPasswordReset(String email) => _mapAuthErrors(() async {
        await _syncEmailLanguage();
        await _auth.sendPasswordResetEmail(email: email);
      });

  Future<void> signInWithGoogle() async {
    final gsi = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await gsi.initialize(
        // Apple platforms take the iOS OAuth client from firebase_options;
        // Android resolves its client via the serverClientId.
        clientId: switch (defaultTargetPlatform) {
          TargetPlatform.iOS ||
          TargetPlatform.macOS =>
            DefaultFirebaseOptions.currentPlatform.iosClientId,
          _ => null,
        },
        serverClientId:
            googleServerClientId.isEmpty ? null : googleServerClientId,
      );
      _googleInitialized = true;
    }
    final GoogleSignInAccount account;
    try {
      account = await gsi.authenticate();
    } on GoogleSignInException catch (e) {
      debugPrint('GoogleSignIn failed: code=${e.code} '
          'description=${e.description} details=${e.details}');
      throw switch (e.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted =>
          const CloudAuthException(CloudAuthErrorCode.canceled),
        _ => CloudAuthException(CloudAuthErrorCode.unknown, e.description),
      };
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      debugPrint('GoogleSignIn: authenticated but no idToken returned');
      throw const CloudAuthException(
          CloudAuthErrorCode.unknown, 'Google returned no idToken');
    }
    await _mapAuthErrors(() => _auth
        .signInWithCredential(GoogleAuthProvider.credential(idToken: idToken)));
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Best-effort: Google session may not exist (email/password sign-in).
    }
    await _auth.signOut();
  }

  Future<T> _mapAuthErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuth error: code=${e.code} message=${e.message}');
      throw CloudAuthException(_mapCode(e.code), e.message);
    }
  }

  static CloudAuthErrorCode _mapCode(String code) => switch (code) {
        'invalid-email' => CloudAuthErrorCode.invalidEmail,
        'user-not-found' => CloudAuthErrorCode.userNotFound,
        // invalid-credential covers wrong password on recent Identity
        // Platform backends (email enumeration protection).
        'wrong-password' ||
        'invalid-credential' ||
        'INVALID_LOGIN_CREDENTIALS' =>
          CloudAuthErrorCode.wrongPassword,
        'email-already-in-use' => CloudAuthErrorCode.emailInUse,
        'weak-password' => CloudAuthErrorCode.weakPassword,
        'network-request-failed' => CloudAuthErrorCode.network,
        _ => CloudAuthErrorCode.unknown,
      };
}
