#!/bin/bash

# Bitcoin Price Tracker Build Script
# This script builds and packages the app for distribution

set -e

PROJECT_NAME="BitcoinPriceStatusBar"
SCHEME_NAME="BitcoinPriceStatusBar"
APP_NAME="Crypto Price Tracker"
BUILD_DIR="build"
DIST_DIR="dist"

echo "🚀 Building Crypto Price Tracker..."

# Clean previous builds
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "📦 Building for Release..."

# Build the app
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    -archivePath "$BUILD_DIR/${APP_NAME}.xcarchive" \
    archive

echo "📁 Exporting app..."

# Export the app
xcodebuild -exportArchive \
    -archivePath "$BUILD_DIR/${APP_NAME}.xcarchive" \
    -exportPath "$DIST_DIR" \
    -exportOptionsPlist "ExportOptions.plist"

echo "📦 Creating DMG..."

# Create DMG
if command -v create-dmg &> /dev/null; then
    create-dmg \
        --volname "${APP_NAME}" \
        --volicon "Assets.xcassets/AppIcon.appiconset/icon_512x512.png" \
        --window-pos 200 120 \
        --window-size 600 300 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 175 120 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 425 120 \
        "${DIST_DIR}/${APP_NAME}.dmg" \
        "${DIST_DIR}/"
else
    echo "⚠️  create-dmg not found. Install with: brew install create-dmg"
fi

echo "✅ Build complete! Check the '$DIST_DIR' folder."
echo "📱 App location: $DIST_DIR/${APP_NAME}.app"

# Show file sizes
echo "📊 File sizes:"
du -sh "$DIST_DIR"/*