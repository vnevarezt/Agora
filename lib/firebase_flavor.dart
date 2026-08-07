// Flavor-aware Firebase selection. This file is COMMITTED (no secrets — pure
// logic); the per-project values live in the gitignored firebase_options*.dart
// and cloud_secrets.dart.
//
// Two Firebase projects: `prod` (agora-vnevarezt, real users) and `dev` (a
// separate project for testing without touching prod). The flavor is chosen at
// launch with `flutter run --flavor dev|prod`, which injects the framework
// define FLUTTER_APP_FLAVOR; `--dart-define=FLAVOR=` is the fallback for web and
// tests, where a native flavor is not passed.
//
// DEFAULT = dev, deliberately: a build with no flavor must never reach prod by
// accident. Release / store builds MUST pass `--flavor prod`.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

import 'cloud_secrets.dart' as secrets;
import 'firebase_options.dart' as prod;
import 'firebase_options_dev.dart' as dev;

enum Flavor { dev, prod }

// FLUTTER_APP_FLAVOR is set by `--flavor` (it cannot be passed via --dart-define
// — the tool reserves it); FLAVOR is our own define for web/tests.
const _nativeFlavor = String.fromEnvironment('FLUTTER_APP_FLAVOR');
const _defineFlavor = String.fromEnvironment('FLAVOR');
const _flavor = _nativeFlavor != '' ? _nativeFlavor : _defineFlavor;

/// Resolved at compile time from `--flavor` or `--dart-define=FLAVOR`.
const Flavor currentFlavor = _flavor == 'prod' ? Flavor.prod : Flavor.dev;

/// The Firebase project config for the running flavor. Throws [UnsupportedError]
/// on platforms the flavor was not configured for (same contract as the
/// generated `DefaultFirebaseOptions.currentPlatform`).
FirebaseOptions get currentFirebaseOptions => switch (currentFlavor) {
      Flavor.prod => prod.DefaultFirebaseOptions.currentPlatform,
      Flavor.dev => dev.DefaultFirebaseOptions.currentPlatform,
    };

/// OAuth Web client id for Android google_sign_in, for the running flavor.
/// Empty string when not configured (the Google button hides itself).
String get googleServerClientId =>
    secrets.googleServerClientId[currentFlavor.name] ?? '';

/// reCAPTCHA v3 site key for web App Check, for the running flavor. Empty
/// string skips web App Check.
String get googleRecaptchaV3SiteKey =>
    secrets.googleRecaptchaV3SiteKey[currentFlavor.name] ?? '';
