# Cloud setup (optional): your own Firebase project

Agora is **local-first**: after cloning you can build and use everything
without any cloud configuration. The cloud account (Firebase Auth) is an
optional identity used for future sync, and every piece of its configuration
is **per-developer and gitignored** — you plug in *your own* Firebase project
and nothing of it can end up in the repository.

## 0. Bootstrap (once per clone)

```sh
sh tool/bootstrap.sh
```

This copies the committed `.example` placeholders to their real, gitignored
locations. The app now builds and runs fully local; Settings shows
"Cloud not configured".

| Real file (gitignored)                          | Purpose                                    |
| ----------------------------------------------- | ------------------------------------------ |
| `lib/firebase_options.dart`                     | Firebase project config (all platforms)    |
| `lib/cloud_secrets.dart`                        | OAuth web client ID (Google on Android)    |
| `ios/Flutter/FirebaseSecrets.xcconfig`          | `GOOGLE_REVERSED_CLIENT_ID` for iOS        |
| `macos/Runner/Configs/FirebaseSecrets.xcconfig` | `GOOGLE_REVERSED_CLIENT_ID` for macOS      |

`firebase.json`, `.firebaserc`, `google-services.json` and
`GoogleService-Info.plist` are gitignored too: the app never reads them
(Firebase initializes from Dart only), they are just CLI byproducts.

## 1. Create the Firebase project and enable providers

1. [console.firebase.google.com](https://console.firebase.google.com) →
   **Add project** (any name, Analytics optional).
2. **Build → Authentication → Get started → Sign-in method**: enable
   **Email/Password** and **Google** (the Google provider asks for a support
   email; enabling it auto-creates the OAuth clients used below).

## 2. Generate your `firebase_options.dart`

```sh
# once per machine
curl -sL https://firebase.tools | bash   # or: brew install firebase-cli
dart pub global activate flutterfire_cli

firebase login                            # use the account that owns the project
flutterfire configure --platforms=android,ios,macos,windows
```

Pick your project; the CLI registers one app per platform and **overwrites
`lib/firebase_options.dart`** (gitignored, so it cannot leak). With just this,
**email/password sign-in already works** on every platform.

> Audit the diff afterwards: `flutterfire` may also drop a
> `firebase.json` / `google-services.json` / `GoogleService-Info.plist` or
> edit `android/…/build.gradle*`. Delete/revert those — this app does not use
> the google-services Gradle plugin, and the plists are unused. `git status`
> must show nothing new outside gitignored paths.

## 3. Only for Google Sign-In (per platform)

- **Android** — two things:
  1. Add your debug SHA-1 to the Android app in *Project settings*:
     `keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android | grep SHA1`
  2. Paste the **Web client** OAuth ID (Google Cloud console → *APIs &
     Services → Credentials*, it looks like `…apps.googleusercontent.com`)
     into `googleServerClientId` in `lib/cloud_secrets.dart`.
     While it is empty the Google button stays hidden on Android.
- **iOS / macOS** — find the **iOS client** in the same Credentials page and
  copy its *reversed* ID (starts with `com.googleusercontent.apps.`), or
  download the `GoogleService-Info.plist` once, copy `REVERSED_CLIENT_ID`,
  and delete the plist. Paste it into **both**
  `ios/Flutter/FirebaseSecrets.xcconfig` and
  `macos/Runner/Configs/FirebaseSecrets.xcconfig`:

  ```
  GOOGLE_REVERSED_CLIENT_ID = com.googleusercontent.apps.1234567890-abc…
  ```

  `Info.plist` references it as a build variable, so the value never enters
  git history.
- **Windows** — `google_sign_in` has no Windows implementation; the button is
  hidden automatically. `firebase_auth` support on Windows is beta: if
  initialization fails the app just runs local.
- **macOS** — FirebaseAuth AND the Google SDK persist sessions in the
  data-protection keychain, which requires a provisioning profile; free Apple
  accounts can't issue macOS profiles, so **cloud mode hides itself on such
  installs** (a runtime keychain probe in `cloudAuthSupportedProvider`; local
  mode always works). Signing with a paid Apple Developer team's managed
  profile makes the probe pass and cloud mode appear — no code changes.

## 4. Verify

- `flutter run -d macos` → Settings → *Cloud account* now offers sign-in;
  create an account and check it appears in Firebase console → Authentication.
- Quit and relaunch: the session persists (`keychain-access-groups` is
  present in both entitlement files; the app itself uses the classic
  file-based keychain, which works under plain development signing).
- The **local password is always the gate to your data**. Cloud sign-in
  never unlocks the local database, and signing out of the cloud never locks
  it.

## 5. Firestore (phase 4b: cloud sync)

Cloud SYNC (not just auth) needs Firestore + the security rules deployed.
The rules are the deployed security model, so **`firestore.rules` and
`firestore.indexes.json` ARE committed** (they contain no secrets). Only
`firebase.json` / `.firebaserc` stay gitignored (per-dev project ids);
`bootstrap.sh` seeds them from the committed `.example` files.

1. Firebase console → **Firestore Database** → *Create database* → Native
   mode, region `nam5` (or your closest). Free (Spark) plan is enough — the
   whole design avoids Cloud Functions.
2. Point the CLI at your project: edit `.firebaserc` (created by bootstrap)
   or pass `--project <id>`.
3. Deploy the rules + the one collection-group index:
   ```sh
   firebase deploy --only firestore:rules,firestore:indexes --project <id>
   ```
   Re-run this whenever `firestore.rules` changes (e.g. after pulling the
   4b-3 `meta/activity` heartbeat rule) — an outdated deploy denies the new
   paths and sync silently stops.
4. In the app: Settings → *Cloud sync* → create your **sync passphrase**
   (encrypts everything E2E; you'll need it on each new device — it is NOT
   recoverable). Then Congregation tab → *Activar en la nube* to upload a
   congregation. A second device on the SAME account, same passphrase, pulls
   it automatically.

### Testing the rules locally (no billing)

```sh
# Java is required (the emulator is a JAR). Android Studio ships one:
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
firebase emulators:exec --only firestore 'npm --prefix tool/rules-test test'
```

## Never commit

Everything the bootstrap creates is gitignored (config with per-dev ids and
secrets). `firestore.rules` / `firestore.indexes.json` are the exception —
they are committed on purpose. Before pushing, this must print **only
`.example` files**:

```sh
git ls-files | grep -iE 'google-services|GoogleService|firebase_options|cloud_secrets|FirebaseSecrets'
```
