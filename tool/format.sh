#!/bin/sh
# Formats the repo with the pinned toolchain, and refuses under any other one.
#
# dart_style's output changes between SDK releases, and the repo is formatted
# for exactly one of them. Running the formatter off-pin rewrites files nobody
# edited — that is how 211 of 304 sources once ended up disagreeing at the same
# time — which lands as a diff no reviewer can read, wrapped around whatever
# change it came with.
#
# On-pin this is a no-op: `sh tool/format.sh --output none` should always
# report 0 changed on a clean tree.
set -eu

cd "$(dirname "$0")/.."
. tool/sdk.sh

exec $DART format "$@" lib test
