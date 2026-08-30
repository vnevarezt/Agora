#!/bin/sh
# Formats the repo with the pinned toolchain, and refuses under any other one.
#
# dart_style's output changes between SDK releases, so formatting off-pin
# rewrites files nobody edited: 207 of 295 sources disagreed between Flutter
# 3.44 and the pinned 3.47. That lands as a diff no reviewer can read, and it
# buries the change it was supposed to accompany.
set -eu

cd "$(dirname "$0")/.."
. tool/sdk.sh

exec $DART format "$@" lib test
