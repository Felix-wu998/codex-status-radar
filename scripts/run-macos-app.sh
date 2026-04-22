#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="CodexStatusRadarApp"
DEMO_MODE=0
for arg in "$@"; do
  if [[ "$arg" == "--demo-approval" ]]; then
    DEMO_MODE=1
  fi
done

if [[ "$DEMO_MODE" == "1" ]]; then
  APP_DIR="$ROOT_DIR/.build/app/Codex Status Radar Demo.app"
  BUNDLE_ID="app.codex-status-radar.local-demo"
  BUNDLE_NAME="Codex Status Radar Demo"
else
  APP_DIR="$ROOT_DIR/.build/app/Codex Status Radar.app"
  BUNDLE_ID="app.codex-status-radar.local"
  BUNDLE_NAME="Codex Status Radar"
fi

CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

cd "$ROOT_DIR"
swift build --disable-sandbox --product "$APP_NAME"
BIN_DIR="$(swift build --disable-sandbox --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
cp "$BIN_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"
printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>CodexStatusRadarApp</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$BUNDLE_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
PLIST

if [[ "$DEMO_MODE" != "1" ]]; then
  cat >> "$CONTENTS_DIR/Info.plist" <<'PLIST'
  <key>LSUIElement</key>
  <true/>
PLIST
fi

cat >> "$CONTENTS_DIR/Info.plist" <<'PLIST'
</dict>
</plist>
PLIST

if [[ "$DEMO_MODE" == "1" ]]; then
  killall "$APP_NAME" 2>/dev/null || true
fi

/usr/bin/codesign --force --sign - "$APP_DIR" >/dev/null 2>&1 || true

if ! open -n "$APP_DIR" --args "$@"; then
  echo "无法通过 open 启动 macOS app，改用直接执行模式。" >&2
  exec "$MACOS_DIR/$APP_NAME" "$@"
fi

echo "已启动：$APP_DIR"
