#!/usr/bin/env bash
# Builds a signed, hardened-runtime CmdX.app into ./dist.
#
#   Scripts/build-app.sh                          # ad-hoc signature (local use)
#   SIGN_IDENTITY="Developer ID Application: …" Scripts/build-app.sh
set -euo pipefail

readonly ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly APP_NAME="CmdX"
readonly APP_DIR="$ROOT/dist/$APP_NAME.app"
readonly SIGN_IDENTITY="${SIGN_IDENTITY:--}"

echo "▸ Running tests"
# Warm-up: with Swift 6.4 Command Line Tools, the first test build from a
# clean .build can fail to load the Swift Testing macro plugin. A second
# build succeeds, and any real compile error still fails `swift test` below.
swift build --package-path "$ROOT" --build-tests >/dev/null 2>&1 || true
swift test --package-path "$ROOT"

echo "▸ Building release binary"
swift build --package-path "$ROOT" -c release
readonly BIN_DIR="$(swift build --package-path "$ROOT" -c release --show-bin-path)"

echo "▸ Assembling $APP_NAME.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
install -m 755 "$BIN_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
install -m 644 "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
plutil -lint "$APP_DIR/Contents/Info.plist"

echo "▸ Signing (hardened runtime, identity: $SIGN_IDENTITY)"
codesign --force --options runtime --timestamp=none --sign "$SIGN_IDENTITY" "$APP_DIR"
codesign --verify --strict --verbose=2 "$APP_DIR"

echo "✓ Built $APP_DIR"
