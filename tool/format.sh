#!/bin/sh
# Formats the repo with the Flutter version .fvmrc pins, and refuses to touch
# anything under any other one.
#
# dart_style's output changes between SDK releases, so formatting under an
# off-pin toolchain rewrites files nobody edited: 207 of 295 sources disagree
# between Flutter 3.44 and the pinned 3.47. That lands as a diff no reviewer
# can read, and it buries the change it was supposed to accompany.
set -eu

cd "$(dirname "$0")/.."

pinned=$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .fvmrc)
[ -n "$pinned" ] || { echo "no flutter version in .fvmrc" >&2; exit 1; }

if command -v fvm >/dev/null 2>&1; then
  exec fvm dart format "$@" lib test
fi

running=$(flutter --version 2>/dev/null | sed -n '1s/^Flutter \([^ ]*\).*/\1/p')

if [ "$running" != "$pinned" ]; then
  cat >&2 <<EOF
Refusing to format.

  .fvmrc pins  $pinned
  flutter is   ${running:-unknown}

The formatter's output differs between these, so running it here would
rewrite most of the repo. Either install fvm (\`dart pub global activate fvm\`,
then \`fvm install\`) or switch your Flutter to $pinned.
EOF
  exit 1
fi

exec dart format "$@" lib test
