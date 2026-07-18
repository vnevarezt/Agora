#!/bin/sh
# Copies every committed .example config to its real (gitignored) location,
# skipping files that already exist. After running it the app builds and runs
# fully LOCAL; to enable the optional cloud follow docs/FIREBASE_SETUP.md.
set -eu

cd "$(dirname "$0")/.."

copy_if_missing() {
  src="$1"
  dst="$2"
  if [ -f "$dst" ]; then
    echo "skip   $dst (already exists)"
  else
    cp "$src" "$dst"
    echo "create $dst"
  fi
}

copy_if_missing lib/firebase_options.example.dart lib/firebase_options.dart
copy_if_missing lib/cloud_secrets.example.dart lib/cloud_secrets.dart
copy_if_missing ios/Flutter/FirebaseSecrets.xcconfig.example ios/Flutter/FirebaseSecrets.xcconfig
copy_if_missing macos/Runner/Configs/FirebaseSecrets.xcconfig.example macos/Runner/Configs/FirebaseSecrets.xcconfig
# Firestore rules deploy + emulator config (rules themselves are committed).
copy_if_missing firebase.json.example firebase.json
copy_if_missing .firebaserc.example .firebaserc

echo
echo "Done. The app runs 100% locally with these placeholders."
echo "To enable the cloud (optional): docs/FIREBASE_SETUP.md"
