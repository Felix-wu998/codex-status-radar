#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="CodexStatusRadarApp"
APP_DIR="$ROOT_DIR/.build/app/Codex Status Radar.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

cd "$ROOT_DIR"
swift build --disable-sandbox --product "$APP_NAME"
BIN_DIR="$(swift build --disable-sandbox --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
cp "$BIN_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>CodexStatusRadarApp</string>
  <key>CFBundleIdentifier</key>
  <string>app.codex-status-radar.local</string>
  <key>CFBundleName</key>
  <string>Codex Status Radar</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST

if ! open "$APP_DIR" --args "$@"; then
  echo "无法通过 open 启动 macOS app。你仍然可以在访达中打开：$APP_DIR" >&2
  exit 1
fi
