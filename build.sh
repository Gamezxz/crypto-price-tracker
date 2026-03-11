#!/bin/bash

# Crypto Price Tracker Build Script
# Supports: App Store archive, DMG distribution, or both

set -e

PROJECT_NAME="BitcoinPriceStatusBar"
SCHEME_NAME="BitcoinPriceStatusBar"
APP_NAME="Crypto Price Tracker"
BUILD_DIR="build"
DIST_DIR="dist"

MODE="${1:-appstore}"  # appstore, dmg, or both

echo "Building Crypto Price Tracker..."
echo "Mode: $MODE"

# Clean previous builds
rm -rf "$BUILD_DIR"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "Building for Release (Universal Binary)..."

# Archive the app
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -archivePath "$BUILD_DIR/${APP_NAME}.xcarchive" \
    ONLY_ACTIVE_ARCH=NO \
    archive

if [ $? -ne 0 ]; then
    echo "Archive failed"
    exit 1
fi

echo "Archive created successfully"

if [ "$MODE" = "appstore" ] || [ "$MODE" = "both" ]; then
    echo "Exporting for App Store..."

    xcodebuild -exportArchive \
        -archivePath "$BUILD_DIR/${APP_NAME}.xcarchive" \
        -exportPath "$DIST_DIR/appstore" \
        -exportOptionsPlist "ExportOptions.plist"

    echo "App Store export complete: $DIST_DIR/appstore/"
    echo ""
    echo "To upload to App Store Connect:"
    echo "  xcrun altool --upload-app -f '$DIST_DIR/appstore/${APP_NAME}.pkg' -t macos -u YOUR_APPLE_ID -p YOUR_APP_PASSWORD"
    echo "  OR use Transporter app from the Mac App Store"
fi

if [ "$MODE" = "dmg" ] || [ "$MODE" = "both" ]; then
    echo "Exporting for direct distribution..."

    # Export for Developer ID (direct distribution)
    cat > "$BUILD_DIR/ExportOptions-dmg.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>DYJAX3728R</string>
</dict>
</plist>
EOF

    xcodebuild -exportArchive \
        -archivePath "$BUILD_DIR/${APP_NAME}.xcarchive" \
        -exportPath "$DIST_DIR/dmg" \
        -exportOptionsPlist "$BUILD_DIR/ExportOptions-dmg.plist"

    echo "Creating DMG..."

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
            "${DIST_DIR}/dmg/"
    else
        echo "create-dmg not found. Install with: brew install create-dmg"
    fi
fi

echo ""
echo "Build complete!"
echo "File sizes:"
du -sh "$DIST_DIR"/* 2>/dev/null || true
