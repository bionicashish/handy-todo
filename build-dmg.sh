#!/usr/bin/env bash
set -euo pipefail

APP_NAME="HandyToDo"
VOLUME_NAME="Handy To-Do"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_BUNDLE="$SCRIPT_DIR/$APP_NAME.app"
DMG_PATH="$SCRIPT_DIR/$APP_NAME.dmg"
STAGING_DIR="$SCRIPT_DIR/.dmg-staging"

echo "▶ Building app bundle…"
"$SCRIPT_DIR/build.sh"

if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "✗ App bundle not found at $APP_BUNDLE"
    exit 1
fi

echo "▶ Preparing DMG staging directory…"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

echo "▶ Creating DMG…"
rm -f "$DMG_PATH"
hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo ""
echo "✓ DMG created:"
echo "  $DMG_PATH"
