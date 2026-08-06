#!/bin/sh
# Regenerates the two binaries drift's web backend loads at runtime.
#
# Both are version-coupled: drift_worker.js speaks a wire protocol to the drift
# package compiled into the app, and sqlite3.wasm must match the sqlite3 package
# drift resolves. Rebuild after bumping either dependency in pubspec.yaml, or
# the browser hits a protocol mismatch that native builds never see.
#
# Usage: sh tool/build_web_assets.sh
set -eu

cd "$(dirname "$0")/.."

sqlite3_version=$(awk '/^  sqlite3:/{f=1} f&&/version:/{gsub(/"/,"",$2); print $2; exit}' pubspec.lock)
if [ -z "$sqlite3_version" ]; then
  echo "could not read the sqlite3 version from pubspec.lock" >&2
  exit 1
fi

# Compiled from this project so it links the exact drift version in pubspec.lock
# rather than whatever prebuilt worker happens to sit in the pub cache.
echo "compiling web/drift_worker.js"
dart compile js -O2 -o web/drift_worker.js tool/web/drift_worker.dart

echo "downloading web/sqlite3.wasm (sqlite3 $sqlite3_version)"
curl -fsSL -o web/sqlite3.wasm \
  "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${sqlite3_version}/sqlite3.wasm"

echo "done"
