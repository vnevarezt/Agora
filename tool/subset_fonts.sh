#!/bin/sh
# Regenerates assets/fonts/ from the pristine faces in tool/fonts-src/.
#
# Every family in pubspec.yaml's `fonts:` block is downloaded AND parsed before
# Flutter web can paint its first frame: the engine awaits the whole manifest
# rather than the faces a screen actually asks for (flutter#108660). Worse, it
# does so *after* the wasm has landed and the app has started, so these are the
# last round trips before anything is on screen.
#
# Manrope ships Cyrillic and Greek. Agora is an es/en app whose free text is
# people's names, so those tables are pure latency. Subsetting to Latin +
# Latin-ext cuts the pre-paint font payload roughly in half with no visible
# change.
#
# A glyph outside the subset is not a crash: web falls back to fonts.gstatic.com
# (already allowed by font-src in firebase.json) and native to the system font.
#
# Two formats, because there are now two front ends. The Flutter app gets TTF:
# CanvasKit cannot parse woff2 (flutter#128485). The landing page is ordinary
# HTML, where woff2 is not only supported but roughly half the size — and there
# it is @font-face, so the browser decodes it rather than Skia.
#
# The subset applies to every platform, since pubspec.yaml has no per-platform
# font declarations. That is deliberate: it shrinks the Android and iOS bundles
# for the same reason.
#
# Usage: sh tool/subset_fonts.sh
set -eu

cd "$(dirname "$0")/.."

if ! command -v pyftsubset >/dev/null 2>&1; then
  echo "pyftsubset not found. Install it with:" >&2
  echo "  python3 -m venv ~/.venvs/fonttools" >&2
  echo "  ~/.venvs/fonttools/bin/pip install fonttools" >&2
  echo "  export PATH=\"\$HOME/.venvs/fonttools/bin:\$PATH\"" >&2
  exit 1
fi

# Latin-1, Latin Extended-A/B, Latin Extended Additional, general punctuation
# and currency. Covers Spanish and English outright, plus the accented forms of
# every other Latin-script language a member's name is likely to be written in.
UNICODES="U+0000-00FF,U+0100-017F,U+0180-024F,U+0131,U+0152-0153,U+02BB-02BC,\
U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+1E00-1EFF,U+2000-206F,U+2074,\
U+20A0-20BF,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD"

# Every feature the source faces carry, so this stays a glyph-range cut and
# nothing else. `locl` and `mark`/`mkmk` position the accents this subset exists
# to keep, and `tnum` is what lines up AppText.mono's figures. `numr`/`dnom` are
# only reachable through `frac` — keeping `frac` without them would leave
# fractions rendering wrong rather than not at all.
FEATURES="kern,liga,calt,ccmp,locl,mark,mkmk,tnum,pnum,numr,dnom,frac"

# Explicit rather than a glob over tool/fonts-src: this list is the one in
# pubspec.yaml, and JetBrainsMono-Medium is kept as a source but deliberately
# not shipped (nothing resolves to w500 — see the comment in pubspec.yaml).
FACES="Manrope-Regular Manrope-Medium Manrope-SemiBold Manrope-Bold \
Manrope-ExtraBold JetBrainsMono-SemiBold"

mkdir -p site/fonts

before=0
after=0
web=0
for face in $FACES; do
  src="tool/fonts-src/$face.ttf"
  out="assets/fonts/$face.ttf"
  woff="site/fonts/$face.woff2"
  if [ ! -f "$src" ]; then
    echo "missing source face: $src" >&2
    exit 1
  fi
  pyftsubset "$src" \
    --output-file="$out" \
    --unicodes="$UNICODES" \
    --layout-features="$FEATURES" \
    --no-hinting \
    --desubroutinize \
    --drop-tables+=DSIG
  pyftsubset "$src" \
    --output-file="$woff" \
    --flavor=woff2 \
    --unicodes="$UNICODES" \
    --layout-features="$FEATURES" \
    --no-hinting \
    --desubroutinize \
    --drop-tables+=DSIG
  s=$(wc -c <"$src")
  o=$(wc -c <"$out")
  w=$(wc -c <"$woff")
  before=$((before + s))
  after=$((after + o))
  web=$((web + w))
  echo "  $face  $((s / 1024))K -> ttf $((o / 1024))K, woff2 $((w / 1024))K"
done

echo "app  (ttf):   $((before / 1024))K -> $((after / 1024))K (-$((100 - 100 * after / before))%)"
echo "site (woff2): $((before / 1024))K -> $((web / 1024))K (-$((100 - 100 * web / before))%)"
