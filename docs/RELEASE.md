# Release checklist

Everything in the app itself is release-ready (network permission, signing
hook, hardened auth flows). What remains is per-developer/per-store setup
that cannot live in the repository.

## 1. Version

Bump `version:` in `pubspec.yaml` (`x.y.z+build`). Android maps it to
`versionName`/`versionCode`, iOS to `CFBundleShortVersionString`/`CFBundleVersion`.

## 2. Android

1. Create a keystore (once, **back it up — losing it means losing the
   ability to update the app**):

   ```bash
   keytool -genkey -v -keystore ~/agora-upload.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties` (gitignored):

   ```properties
   storeFile=/Users/you/agora-upload.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```

   Without this file the release build falls back to the **debug key**
   (fine for `flutter run --release`, never for the store).

3. Build and verify:

   ```bash
   flutter build appbundle --release   # Play Store
   flutter build apk --release         # direct distribution
   ```

## 3. iOS

- Signing needs a paid Apple Developer team (the data-protection keychain
  used by Firebase/Google sessions requires a provisioning profile; the
  runtime probe hides cloud mode on machines where that's missing).
- `ios/Flutter/FirebaseSecrets.xcconfig` (gitignored, see the `.example`)
  provides `GOOGLE_REVERSED_CLIENT_ID` for the Google sign-in URL scheme.
- `flutter build ipa --release`.

## 3b. Web

```bash
flutter build web --wasm --no-web-resources-cdn --release
```

Both flags are required.

The default JS build compiles to dart2js and picks the CanvasKit renderer;
`--wasm` compiles to WasmGC and picks skwasm instead. Measured on the sign-in
screen with a cold cache:

| | default | `--wasm` |
| --- | --- | --- |
| transferred | 8.0 MB | 6.2 MB |
| main-thread blocking after first paint | 224 ms | 0 ms |
| worst single task | 274 ms | 0 ms |

The blocking column is the one that matters: it is the visible stutter just
after the UI appears. Flutter emits a dart2js bundle alongside the wasm one and
falls back to it automatically on browsers without WasmGC, so the flag costs
nothing in compatibility.

`--no-web-resources-cdn` bundles CanvasKit instead of pulling it from
`gstatic.com` on every load. Uncompressed that adds ~2MB, but the payload
compresses to about a third (3.4MB of skwasm ships as 1.5MB gzipped) and
hosting compresses automatically, so the real cost is small — and the app stops
announcing itself to a third party on every visit.

**Headers.** `firebase.json.example` carries the deploy configuration. Two
things there are deliberate and easy to "fix" into breakage:

- `Cross-Origin-Opener-Policy` is `same-origin-allow-popups`, not
  `same-origin`. The stricter value is what cross-origin isolation needs (it
  would let drift use OPFS with a SharedArrayBuffer) but it severs
  `window.opener` for cross-origin popups, which is how `signInWithPopup`
  returns the Google credential. Sign-in wins; drift uses IndexedDB.
- The CSP allows `'unsafe-inline'` in `script-src`, because Flutter's bootstrap
  emits inline scripts. The directive doing the work is `connect-src`: it pins
  where anything can be sent, so injected script still cannot exfiltrate the
  congregation to an arbitrary host. This matters because the web database is
  not encrypted (see `lib/data/db/connection_web.dart`).

The allowed third-party origins are not optional and were each confirmed
against a real page load: `www.gstatic.com` serves the Firebase JS SDK that
`firebase_core` loads at runtime, `accounts.google.com` is the GSI client that
`google_sign_in_web` injects when it registers, and `fonts.gstatic.com` is
CanvasKit fetching its Roboto fallback. After changing the policy, load the app
and check the console: a CSP that blocks the engine looks exactly like one that
works until someone opens the page.

`web/sqlite3.wasm` and `web/drift_worker.js` are committed but version-coupled
to `pubspec.lock`. Re-run `sh tool/build_web_assets.sh` after bumping `drift`
or `sqlite3`.

## 4. Firebase console (cloud mode)

- **Authentication → Sign-in method**: enable Email/Password and Google.
- **Templates**: reset/verification emails are sent in the app language
  (the app sets `languageCode` before sending); review the templates once.
- Registration sends a verification email. It is informative only — the
  app never gates access on it.
- Optional hardening: App Check, and keep email enumeration protection on
  (the app already maps `invalid-credential` to "wrong password").

## 5. Auth model reminders (support answers)

- **Local mode**: the password wraps the DB key. Forgotten password =
  unrecoverable data by design; the only path is "start over", which
  deletes the DB and all keys. Recommend exporting backups.
- **Cloud mode**: the Firebase session is the gate; the device key lives
  in the OS keychain. Signing out closes the session but keeps the local
  encrypted data on the device.

## 6. Performance sanity check

Judge jank only on a physical device with `--profile` or `--release`;
debug builds always stutter. The PDF preview renders in a background
isolate, so navigation and typing must stay smooth — if they don't,
profile before shipping.
