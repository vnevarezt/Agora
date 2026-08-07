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

| Real file (gitignored)                               | Purpose                                          |
| ---------------------------------------------------- | ------------------------------------------------ |
| `lib/firebase_options.dart`                          | **prod** Firebase project config (all platforms) |
| `lib/firebase_options_dev.dart`                      | **dev** Firebase project config (all platforms)  |
| `lib/cloud_secrets.dart`                             | OAuth web client ID + App Check key, per flavor  |
| `ios/Flutter/FirebaseSecrets.xcconfig` (+ `-dev`)    | `GOOGLE_REVERSED_CLIENT_ID` iOS, per flavor      |
| `macos/Runner/Configs/FirebaseSecrets.xcconfig` (+ `-dev`) | `GOOGLE_REVERSED_CLIENT_ID` macOS, per flavor |

`firebase.json`, `.firebaserc`, `google-services.json` and
`GoogleService-Info.plist` are gitignored too: the app never reads them
(Firebase initializes from Dart only), they are just CLI byproducts.

## Flavors: `dev` vs `prod` (two Firebase projects)

Two projects keep testing off real users: **`prod`** (the project with your
users) and **`dev`** (a throwaway project for development). Selection is by
flavor at launch — `flutter run --flavor dev|prod` — or the VS Code launch
configs **"Agora dev" / "Agora prod"** (`.vscode/launch.json`).

- The Firebase **project** is chosen in Dart ([lib/firebase_flavor.dart](../lib/firebase_flavor.dart)):
  `--flavor` sets `FLUTTER_APP_FLAVOR`, and the selector picks
  `firebase_options_dev.dart` vs `firebase_options.dart` (web/tests fall back to
  `--dart-define=FLAVOR=`). **Default is `dev`** on purpose — an unflavored build
  never reaches prod. **Store/release builds MUST pass `--flavor prod`.**
- **Side-by-side installs**: `dev` gets `applicationId`/`bundleId` suffix `.dev`,
  so both apps coexist on one device (Android app name shows "Agora Dev").

**Configure each project** (§2 covers prod as the default `firebase_options.dart`;
for dev add `--out` and the `.dev` ids):

```sh
# DEV project (create it in the console first)
flutterfire configure --project=<your-dev-id> \
  --out=lib/firebase_options_dev.dart \
  --android-package-name=com.vnevarezt.agora.dev \
  --ios-bundle-id=com.vnevarezt.agora.dev \
  --macos-bundle-id=com.vnevarezt.agora.dev
```

**Native flavor wiring:**
- **Android** — already set in `android/app/build.gradle.kts` (`productFlavors`
  dev/prod). Nothing else to do.
- **Web / Windows** — no native flavor; the `--dart-define=FLAVOR` in the launch
  configs is enough.
- **iOS / macOS** — one-time Xcode setup:
  1. Duplicate the build configurations into `Debug-dev / Release-dev /
     Profile-dev` and `…-prod`.
  2. Create **schemes** named `dev` and `prod` bound to those configs.
  3. Set `PRODUCT_BUNDLE_IDENTIFIER` = `com.vnevarezt.agora` (prod) and
     `com.vnevarezt.agora.dev` (dev) per config.
  4. Make each config include the matching secrets file — change the
     `#include?` in `ios/Flutter/Debug.xcconfig`/`Release.xcconfig` (and the
     macOS equivalents) to `FirebaseSecrets-$(FLAVOR).xcconfig`, and set a
     `FLAVOR = dev|prod` build setting per config. `Info.plist` already reads
     `$(GOOGLE_REVERSED_CLIENT_ID)`.

`cloud_secrets.dart` values are **maps keyed by flavor** (`{'dev':…, 'prod':…}`).

### Crashlytics (optional)

Crashlytics is wired in `firebaseAppProvider` (see `lib/state/cloud_auth.dart`)
and follows the flavor automatically: a `dev` build reports to the dev project,
`prod` to prod — no per-build code. **Collection is enabled only in release**
(`!kDebugMode`), so debug/dev runs report nothing and the dashboards stay clean;
you see those crashes in the debugger. To use it, enable Crashlytics once per
project in the console (**Release & Monitor → Crashlytics → Enable**). Only
Dart/Flutter errors are captured — full native symbolication (NDK / dSYM) would
need the Crashlytics Gradle plugin, which this app avoids on purpose.

### Analytics (optional — privacy tradeoff)

Firebase Analytics is wired the same way (`_initAnalytics` in
`lib/state/cloud_auth.dart`) and follows the flavor: `dev`→dev, `prod`→prod.
Collection is on in release and, in debug, only for the `dev` flavor (so dev's
**DebugView** works without a local prod-debug run skewing prod). It only runs
when the cloud is configured, so **local-first users are never tracked**. The
usual reports (active users, country/city, devices, sessions) are automatic; no
event code needed. To see the data, enable **Google Analytics** in each
project's console (Project settings → Integrations, or the Analytics tab links a
GA property). Note this sends usage + coarse location to Google — a deliberate
choice for an otherwise E2E/private app.

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

> **Keep the web hosting headers.** The CSP and security headers live in the
> `hosting` block of `firebase.json.example`. `flutterfire configure` rewrites
> `firebase.json` without that block, and `tool/bootstrap.sh` only seeds the
> file when it is missing — so after running `flutterfire`, re-merge the
> `hosting` block from `firebase.json.example` into `firebase.json`, or a
> `firebase deploy --only hosting` ships the web app with no CSP. Verify after
> deploying: `curl -sI https://<your-site> | grep -i content-security-policy`.

## 3. Only for Google Sign-In (per platform)

- **Android** — two things:
  1. Add your debug SHA-1 to the Android app in *Project settings*:
     `keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android | grep SHA1`
  2. Paste the **Web client** OAuth ID (Google Cloud console → *APIs &
     Services → Credentials*, it looks like `…apps.googleusercontent.com`)
     into the matching flavor key of `googleServerClientId` in
     `lib/cloud_secrets.dart` (`{'dev': …, 'prod': …}`).
     While a flavor's value is empty the Google button stays hidden on Android.
- **iOS / macOS** — find the **iOS client** in the same Credentials page and
  copy its *reversed* ID (starts with `com.googleusercontent.apps.`), or
  download the `GoogleService-Info.plist` once, copy `REVERSED_CLIENT_ID`,
  and delete the plist. Paste the **prod** value into
  `ios/Flutter/FirebaseSecrets.xcconfig` +
  `macos/Runner/Configs/FirebaseSecrets.xcconfig`, and the **dev** project's
  value into the `-dev` variants of each:

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
2. `.firebaserc` (created by bootstrap) defines both **dev** and **prod**
   project ids — fill both in.
3. Deploy the rules + the one collection-group index **to each project** (the
   rules are shared, so dev tests exactly what prod runs):
   ```sh
   firebase deploy --only firestore:rules,firestore:indexes --project dev
   firebase deploy --only firestore:rules,firestore:indexes --project prod
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
