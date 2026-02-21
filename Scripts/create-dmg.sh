#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="CCUsageBar"
DMG_NAME="${APP_NAME}.dmg"
DMG_DIR="build/dmg"

# Build the app bundle
bash Scripts/bundle.sh

# Ad-hoc codesign with hardened runtime
codesign --force --deep --options runtime --sign - "build/${APP_NAME}.app"

# Prepare DMG staging dir with app + Applications symlink
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
cp -R "build/${APP_NAME}.app" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

# Create DMG
rm -f "build/${DMG_NAME}"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_DIR" \
  -ov \
  -format UDZO \
  "build/${DMG_NAME}"

rm -rf "$DMG_DIR"

echo "Created: build/${DMG_NAME}"
