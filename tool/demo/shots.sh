#!/usr/bin/env bash
# Renders the store/landing captures from the real app and copies them out of
# the sandboxed macOS container into build/demo/shots/.
#
#   tool/demo/shots.sh                 # every size, both languages
#   tool/demo/shots.sh phone           # one size
#   tool/demo/shots.sh phone,tablet7 es
#   tool/demo/shots.sh --fetch         # only collect what is already rendered
#
# Deliberately not `set -e`: a run that dies halfway still leaves usable PNGs
# in the container, and collecting them is the whole point of this script.
set -uo pipefail

cd "$(dirname "$0")/../.."
out="build/demo/shots"
mkdir -p "$out"

# collect [cutoff-epoch]
#
# Copies with -p on purpose. Without it the copy stamps every file with the
# time it was copied, so a run whose render never fired hands you last week's
# captures wearing today's date — and the frames built on top of them ship an
# app that no longer exists.
collect() {
  local src cutoff stale=0 total newest
  cutoff=${1:-0}
  src=$(ls -d "$HOME"/Library/Containers/*/Data/Documents/agora-shots 2>/dev/null | head -1)
  if [ -z "$src" ]; then
    echo "No captures found. The app writes them inside its sandbox container;" >&2
    echo "if it ran at all, check ~/Library/Containers/*/Data/Documents." >&2
    return 1
  fi
  if ! cp -p "$src"/*.png "$out"/ 2>/dev/null; then
    echo
    echo "Could not read the app container. Grant your terminal Full Disk Access"
    echo "(System Settings -> Privacy & Security -> Full Disk Access), or copy"
    echo "them yourself from:"
    echo "  $src"
    return 1
  fi

  total=$(ls -1 "$out"/*.png 2>/dev/null | wc -l | tr -d ' ')
  [ "$total" -eq 0 ] && { echo "Nothing was collected." >&2; return 1; }
  newest=$(ls -t "$out"/*.png | head -1)
  echo
  echo "$total captures in $out (newest $(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$newest"))"

  # Nothing to compare against on a bare --fetch: the age above is the answer.
  [ "$cutoff" -eq 0 ] && return 0

  for f in "$out"/*.png; do
    [ "$(stat -f %m "$f")" -lt "$cutoff" ] && stale=$((stale + 1))
  done
  if [ "$stale" -gt 0 ]; then
    echo >&2
    echo "$stale of those are older than this run: the render did not replace" >&2
    echo "them. Framing this set publishes a version of the app that is gone." >&2
    echo "Re-run the capture with the Agora window visible and frontmost." >&2
    return 1
  fi
}

if [ "${1:-}" = "--fetch" ]; then
  collect
  exit $?
fi

# Anything older than this when the run ends was not written by this run.
started=$(date +%s)

echo "The Agora window must stay VISIBLE and frontmost for this to work:"
echo "the capture loop runs on that window's vsync. Covered, it crawls;"
echo "never shown at all (locked screen, another Space), it hangs outright."
echo "Do not run this in the background."
echo

flutter test integration_test/screenshots_test.dart -d macos \
  --dart-define=SHOTS_TARGETS="${1:-}" \
  --dart-define=SHOTS_LOCALES="${2:-}"
status=$?

collect "$started" || exit 1
exit $status
