#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Building CCUsageBar..."
swift build -c release

APP_DIR="build/CCUsageBar.app/Contents/MacOS"
mkdir -p "$APP_DIR"
cp ".build/release/CCUsageBar" "$APP_DIR/"
cp "Resources/Info.plist" "build/CCUsageBar.app/Contents/"

echo "Built: build/CCUsageBar.app"
echo "Run with: open build/CCUsageBar.app"
