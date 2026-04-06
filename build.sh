#!/usr/bin/env bash
set -euo pipefail

APP_NAME="HandyToDo"
BUNDLE_ID="com.handytodo.app"
VERSION="1.0.0"
MIN_MACOS="14.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_BUNDLE="$SCRIPT_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

# Kill any running instance first
pkill -x "$APP_NAME" 2>/dev/null && echo "▶ Stopped running instance" || true

echo "▶ Building $APP_NAME (release)…"
cd "$SCRIPT_DIR"
swift build -c release 2>&1

BINARY="$SCRIPT_DIR/.build/release/$APP_NAME"
if [[ ! -f "$BINARY" ]]; then
    echo "✗ Build failed: binary not found at $BINARY"
    exit 1
fi
echo "✓ Build succeeded"

echo "▶ Bundling app…"
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BINARY" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

cat > "$CONTENTS/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>Handy To-Do</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_MACOS}</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>
</dict>
</plist>
PLIST

plutil -lint "$CONTENTS/Info.plist" > /dev/null && echo "✓ Info.plist valid"

# Remove quarantine so macOS doesn't block unsigned app
xattr -dr com.apple.quarantine "$APP_BUNDLE" 2>/dev/null || true

echo ""
echo "✓ Done! Run with:"
echo "  open \"$APP_BUNDLE\""
