// Per-developer OAuth values — copy to lib/cloud_secrets.dart
// (`sh tool/bootstrap.sh` does it). The real file is gitignored.
//
// [googleServerClientId] is the OAuth 2.0 *Web* client ID of your Firebase
// project (Google Cloud console → APIs & Services → Credentials). Android's
// google_sign_in needs it to mint the idToken Firebase consumes. Leave it
// empty to hide the Google button on Android; iOS/macOS don't use it.
const String googleServerClientId = '';
