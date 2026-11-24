#!/usr/bin/env bash
#
# Release build with reverse-engineering hardening.
#
# Dart compiles to native, but without --obfuscate the function/class names
# survive in the binary and make decompilation easy. This script turns on
# Dart symbol obfuscation and saves the symbol map so crash reports can still
# be de-obfuscated later.
#
# Usage:
#   ./scripts/build_release.sh aab     # Play Store bundle (default)
#   ./scripts/build_release.sh apk     # sideload / direct APK
#
# The symbol maps land in build-symbols/<version>/ — DO NOT ship them, but DO
# archive them somewhere safe. You need them to read obfuscated stack traces.
set -euo pipefail

cd "$(dirname "$0")/.."

TARGET="${1:-aab}"
VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
SYMBOLS_DIR="build-symbols/${VERSION}"

mkdir -p "$SYMBOLS_DIR"

COMMON_ARGS=(
  --release
  --obfuscate
  --split-debug-info="$SYMBOLS_DIR"
)

echo "Building $TARGET for version $VERSION (obfuscated)…"
echo "Symbol map: $SYMBOLS_DIR (keep this to de-obfuscate crashes)"

case "$TARGET" in
  aab)
    flutter build appbundle "${COMMON_ARGS[@]}"
    ;;
  apk)
    flutter build apk "${COMMON_ARGS[@]}"
    ;;
  *)
    echo "Unknown target '$TARGET'. Use 'aab' or 'apk'." >&2
    exit 1
    ;;
esac

echo "Done. Archive $SYMBOLS_DIR before releasing."
