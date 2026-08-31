# Resolves the pinned toolchain. Source it; do not run it.
#
# .fvmrc pins the Flutter version and nothing else enforces it, so every script
# here goes through fvm. It is looked for on PATH first and then in pub's own
# bin, which is where `dart pub global activate` puts it and which is not on
# PATH on a default macOS shell — the reason the guard in format.sh used to
# report fvm missing on a machine that had it.
#
# Exports FLUTTER and DART, each a command prefix to invoke rather than a path.

_fvm=""
if command -v fvm >/dev/null 2>&1; then
  _fvm="fvm"
elif [ -x "$HOME/.pub-cache/bin/fvm" ]; then
  _fvm="$HOME/.pub-cache/bin/fvm"
fi

_pinned=$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .fvmrc)
[ -n "$_pinned" ] || { echo "no flutter version in .fvmrc" >&2; exit 1; }

if [ -n "$_fvm" ]; then
  FLUTTER="$_fvm flutter"
  DART="$_fvm dart"
  return 0 2>/dev/null || true
fi

# No fvm: only proceed if the Flutter on PATH happens to be the pinned one.
_running=$(flutter --version 2>/dev/null | sed -n '1s/^Flutter \([^ ]*\).*/\1/p')
if [ "$_running" != "$_pinned" ]; then
  cat >&2 <<EOF
Wrong toolchain.

  .fvmrc pins  $_pinned
  flutter is   ${_running:-not found}

Install fvm and the pinned SDK:

  dart pub global activate fvm
  export PATH="\$PATH:\$HOME/.pub-cache/bin"   # add to your ~/.zshrc
  fvm install

Everything under tool/ goes through it, and so should you: \`fvm flutter test\`.
EOF
  exit 1
fi

FLUTTER="flutter"
DART="dart"
