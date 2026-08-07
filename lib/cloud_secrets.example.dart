// Per-developer OAuth values — copy to lib/cloud_secrets.dart
// (`sh tool/bootstrap.sh` does it). The real file is gitignored.
//
// [googleServerClientId] is the OAuth 2.0 *Web* client ID of your Firebase
// project (Google Cloud console → APIs & Services → Credentials). Android's
// google_sign_in needs it to mint the idToken Firebase consumes. Leave it
// empty to hide the Google button on Android; iOS/macOS don't use it.
const String googleServerClientId = '';

/// reCAPTCHA v3 **site key** for Firebase App Check on the web (Firebase console
/// → App Check → your Web app → reCAPTCHA v3). Public by design — it ships in the
/// web bundle. Leave empty to skip App Check on the web; native platforms use
/// Play Integrity / DeviceCheck and need no key here. App Check only attaches an
/// attestation token, so shipping this empty changes nothing until you turn on
/// *enforcement* in the console.
const String googleRecaptchaV3SiteKey = '';
