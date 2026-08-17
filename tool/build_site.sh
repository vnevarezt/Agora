#!/bin/sh
# Builds the deployable site: static landing at /, Flutter app under /app/.
#
# The split is the whole point. A visitor who has never heard of Agora gets
# ~11 KB of HTML and CSS and sees the page immediately; the ~3.4 MB engine is
# only ever paid by someone who has decided to use the product, and by then
# landing.js has already been fetching it in the background while they read.
#
# Everything under build/site is generated. Sources are site/ and lib/.
#
# Usage: sh tool/build_site.sh [flavor]   (flavor defaults to prod)
set -eu

cd "$(dirname "$0")/.."

flavor="${1:-prod}"
out="build/site"

# Stale output would survive a renamed file and get deployed alongside the new
# one, which is how a site ends up serving a page nobody can find in the repo.
rm -rf "$out"

echo "generating tokens"
python3 tool/gen_css_tokens.py

echo "building the app for /app/"
# --base-href is what lets the app live in a subdirectory: Flutter resolves its
# own asset and engine URLs against it, so the bundle does not go looking for
# /main.dart.wasm at the root where the landing lives.
flutter build web \
  --wasm \
  --no-web-resources-cdn \
  --release \
  --base-href /app/ \
  --dart-define="FLAVOR=$flavor"

mkdir -p "$out"
mv build/web "$out/app"

echo "rendering the landing"
python3 tool/build_site.py

echo
echo "built $out"
du -sh "$out/app" "$out" 2>/dev/null | sed 's/^/  /'
