// Per-developer OAuth values — copy to lib/cloud_secrets.dart
// (`sh tool/bootstrap.sh` does it). The real file is gitignored.
//
// Values are keyed by flavor ('dev' | 'prod'): each Firebase project has its
// own OAuth clients and App Check keys. The running flavor picks one — see
// lib/firebase_flavor.dart.
//
// [googleServerClientId] is the OAuth 2.0 *Web* client ID of each Firebase
// project (Google Cloud console → APIs & Services → Credentials). Android's
// google_sign_in needs it to mint the idToken Firebase consumes. Leave a flavor
// empty to hide the Google button on Android for that flavor; iOS/macOS don't
// use it.
const Map<String, String> googleServerClientId = {
  'dev': 'REPLACE_ME',
  'prod': 'REPLACE_ME',
};

/// reCAPTCHA v3 **site key** for Firebase App Check on the web, per flavor
/// (Firebase console → App Check → your Web app → reCAPTCHA v3). Public by
/// design — it ships in the web bundle. Leave a flavor empty to skip web App
/// Check there; native platforms use Play Integrity / DeviceCheck and need no
/// key here. App Check only attaches an attestation token, so shipping these
/// empty changes nothing until you turn on *enforcement* in the console.
const Map<String, String> googleRecaptchaV3SiteKey = {
  'dev': '',
  'prod': '',
};
