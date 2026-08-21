#!/usr/bin/env bash
# Frames the captures in build/demo/shots/ into device mockups.
#
#   tool/demo/frames.sh              # store frames + landing heroes
#   tool/demo/frames.sh hero         # only the heroes
#   tool/demo/frames.sh store es     # only the Spanish store frames
#
# Needs the captures first: tool/demo/shots.sh
set -euo pipefail

cd "$(dirname "$0")/../.."

chrome="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
if [ ! -x "$chrome" ]; then
  echo "Google Chrome is required to render the frames (it does the compositing)." >&2
  exit 1
fi

node tool/demo/frames/render.mjs "$@"
