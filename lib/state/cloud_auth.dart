import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_flavor.dart';
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
  tooManyRequests,
  canceled,
  /// The session is too old for a sensitive op (delete): reauthenticate first.
  requiresRecentLogin,
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
    options = currentFirebaseOptions;
  } on UnsupportedError {
    return null;
  }
  if (options.apiKey.startsWith('REPLACE')) return null;
  try {
    final app = await Firebase.initializeApp(options: options);
    await _activateAppCheck();
    await _initCrashlytics();
    await _initAnalytics();
    return app;
  } catch (e) {
    debugPrint('Firebase init failed, cloud disabled: $e');
    return null;
  }
});

/// Best-effort Firebase App Check activation. Attests that requests come from a
/// genuine instance of this app, so once *enforcement* is enabled in the
/// Firebase console the backend can reject direct API calls that carry only a
/// stolen auth token. Deliberately best-effort: enforcement stays OFF until the
/// project is configured, so a failure here changes nothing and must never
/// disable the cloud (same contract as the rest of this file). Web needs a
/// reCAPTCHA v3 site key ([googleRecaptchaV3SiteKey]); left empty, web App Check
/// is skipped. Native uses Play Integrity / DeviceCheck in release and the debug
/// providers otherwise (register the printed debug token in the console).
Future<void> _activateAppCheck() async {
  try {
    if (kIsWeb) {
      if (googleRecaptchaV3SiteKey.isEmpty) return;
      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider(googleRecaptchaV3SiteKey),
      );
    } else {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode
            ? const AppleDebugProvider()
            : const AppleDeviceCheckProvider(),
      );
    }
  } catch (e) {
    debugPrint('App Check activation skipped: $e');
  }
}

/// Wires Crashlytics to the running Firebase project — a `dev` build reports to
/// the dev project, `prod` to prod, by flavor (no per-build code needed).
/// Collection is enabled only in RELEASE: debug/dev runs report nothing (you
/// watch those in the debugger), which keeps the dashboards clean. Best-effort —
/// never breaks cloud init. Dart/Flutter errors are captured; full native
/// symbolication (NDK / dSYM) would need the Crashlytics Gradle plugin, which
/// this app deliberately avoids (Firebase is Dart-only here).
Future<void> _initCrashlytics() async {
  try {
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    final priorOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      priorOnError?.call(details); // keep the console / red screen in debug
      crashlytics.recordFlutterError(details); // sent only when collection is on
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Crashlytics setup skipped: $e');
  }
}

/// Enables Firebase Analytics for the running project (dev→dev, prod→prod by
/// flavor). Collection is on in release, and in debug ONLY for the dev flavor —
/// so you can verify events in dev's DebugView without a local prod-debug run
/// skewing prod's numbers. Best-effort. The reports you usually want (active
/// users, geography, devices, sessions) are automatic; no extra code. Runs only
/// when the cloud is configured, so local-first users are never tracked.
Future<void> _initAnalytics() async {
  try {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
      !kDebugMode || currentFlavor == Flavor.dev,
    );
  } catch (e) {
    debugPrint('Analytics setup skipped: $e');
  }
}

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
    // google_sign_in leaves authenticate() unimplemented on the web: Google
    // Identity Services only starts the flow from its own rendered button.
    // firebase_auth drives that popup itself, so the web path skips the
    // id-token dance and hands Firebase the provider directly.
    if (kIsWeb) {
      await _mapAuthErrors(() => _auth.signInWithPopup(GoogleAuthProvider()));
      return;
    }
    final idToken = await _freshGoogleIdToken();
    await _mapAuthErrors(() => _auth
        .signInWithCredential(GoogleAuthProvider.credential(idToken: idToken)));
  }

  /// Runs the interactive Google flow and returns a fresh id token, shared by
  /// [signInWithGoogle] and [reauthenticateWithGoogle]. Throws
  /// [CloudAuthErrorCode.canceled] when the user dismisses the sheet.
  Future<String> _freshGoogleIdToken() async {
    final gsi = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await gsi.initialize(
        // Apple platforms take the iOS OAuth client from firebase_options;
        // Android resolves its client via the serverClientId.
        clientId: switch (defaultTargetPlatform) {
          TargetPlatform.iOS ||
          TargetPlatform.macOS =>
            currentFirebaseOptions.iosClientId,
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
    return idToken;
  }

  Future<void> signOut() async {
    // On the web the Google session lives in the popup's Firebase credential,
    // which _auth.signOut() clears; GoogleSignIn was never initialised there.
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Best-effort: Google session may not exist (email/password sign-in).
      }
    }
    await _auth.signOut();
  }

  // ---- account deletion -----------------------------------------------------

  /// Sign-in provider of the current user ('password' | 'google.com'), so the
  /// UI knows whether to ask for a password or re-run Google to reauthenticate.
  /// Null when signed out or when no provider is recorded.
  String? get currentProviderId =>
      _auth.currentUser?.providerData.firstOrNull?.providerId;

  /// Email of the current user (for the email reauth credential).
  String? get currentEmail => _auth.currentUser?.email;

  /// Reauthenticates a password user — deleting the account needs a recent
  /// login. Reuses [signInWithGoogle]'s credential path for Google users.
  Future<void> reauthenticateWithEmail(String password) =>
      _mapAuthErrors(() async {
        final user = _auth.currentUser;
        final email = user?.email;
        if (user == null || email == null) {
          throw const CloudAuthException(CloudAuthErrorCode.userNotFound);
        }
        await user.reauthenticateWithCredential(
            EmailAuthProvider.credential(email: email, password: password));
      });

  /// Reauthenticates a Google user by re-running the Google flow and feeding a
  /// fresh credential back. Throws [CloudAuthErrorCode.canceled] if dismissed.
  Future<void> reauthenticateWithGoogle() async {
    if (kIsWeb) {
      await _mapAuthErrors(() async {
        final user = _auth.currentUser;
        if (user == null) {
          throw const CloudAuthException(CloudAuthErrorCode.userNotFound);
        }
        await user.reauthenticateWithPopup(GoogleAuthProvider());
      });
      return;
    }
    final idToken = await _freshGoogleIdToken();
    await _mapAuthErrors(() async {
      final user = _auth.currentUser;
      if (user == null) {
        throw const CloudAuthException(CloudAuthErrorCode.userNotFound);
      }
      await user.reauthenticateWithCredential(
          GoogleAuthProvider.credential(idToken: idToken));
    });
  }

  /// Deletes the Firebase Auth account. The caller must have reauthenticated
  /// recently; otherwise this throws [CloudAuthErrorCode.requiresRecentLogin]
  /// and the UI prompts to reauth. Best-effort Google sign-out afterwards.
  Future<void> deleteAccount() => _mapAuthErrors(() async {
        final user = _auth.currentUser;
        if (user == null) {
          throw const CloudAuthException(CloudAuthErrorCode.userNotFound);
        }
        await user.delete();
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      });

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
        // Windows' firebase_auth plugin doesn't recognize
        // INVALID_LOGIN_CREDENTIALS (email enumeration protection) and falls
        // back to this generic code instead of invalid-credential.
        'unknown-error' when defaultTargetPlatform == TargetPlatform.windows =>
          CloudAuthErrorCode.wrongPassword,
        'email-already-in-use' => CloudAuthErrorCode.emailInUse,
        'weak-password' => CloudAuthErrorCode.weakPassword,
        'network-request-failed' => CloudAuthErrorCode.network,
        'too-many-requests' => CloudAuthErrorCode.tooManyRequests,
        // Web popup flow: dismissing the window is a cancel, not a failure —
        // the native path reports the same thing from GoogleSignInException.
        'popup-closed-by-user' ||
        'cancelled-popup-request' ||
        'user-cancelled' =>
          CloudAuthErrorCode.canceled,
        'requires-recent-login' => CloudAuthErrorCode.requiresRecentLogin,
        _ => CloudAuthErrorCode.unknown,
      };
}
