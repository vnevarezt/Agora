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

Always build with `--wasm`:

```bash
flutter build web --wasm --release
```

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

Serve with cross-origin isolation (`Cross-Origin-Opener-Policy: same-origin`
and `Cross-Origin-Embedder-Policy: require-corp`) so drift can use OPFS; without
those headers it still works, on the slower IndexedDB path.

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
