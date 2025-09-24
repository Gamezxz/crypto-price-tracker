#!/bin/bash

# Build Bitcoin Price Tracker using Swift compiler directly
# This works without full Xcode

set -e

APP_NAME="Crypto Price Tracker"
BUILD_DIR="build_swift"
DIST_DIR="dist"
BUNDLE_ID="com.crypto.pricetracker"

echo "🚀 Building Crypto Price Tracker with Swift compiler..."

# Clean previous builds
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR" "$DIST_DIR"

# Create app bundle structure
APP_BUNDLE="$BUILD_DIR/${APP_NAME}.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "📋 Creating Info.plist..."

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>BitcoinPriceTracker</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>Crypto Price Tracker</string>
    <key>CFBundleDisplayName</key>
    <string>Crypto Price Tracker</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>api.binance.com</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <false/>
                <key>NSExceptionMinimumTLSVersion</key>
                <string>TLSv1.2</string>
                <key>NSExceptionRequiresForwardSecrecy</key>
                <false/>
            </dict>
            <key>fapi.binance.com</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <false/>
                <key>NSExceptionMinimumTLSVersion</key>
                <string>TLSv1.2</string>
                <key>NSExceptionRequiresForwardSecrecy</key>
                <false/>
            </dict>
            <key>stream.binance.com</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <false/>
                <key>NSExceptionMinimumTLSVersion</key>
                <string>TLSv1.2</string>
                <key>NSExceptionRequiresForwardSecrecy</key>
                <false/>
            </dict>
            <key>fstream.binance.com</key>
            <dict>
                <key>NSExceptionAllowsInsecureHTTPLoads</key>
                <false/>
                <key>NSExceptionMinimumTLSVersion</key>
                <string>TLSv1.2</string>
                <key>NSExceptionRequiresForwardSecrecy</key>
                <false/>
            </dict>
        </dict>
    </dict>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 Crypto Price Tracker. All rights reserved.</string>
</dict>
</plist>
EOF

echo "🔨 Compiling Swift code..."

# Compile Swift files
swiftc -o "$APP_BUNDLE/Contents/MacOS/BitcoinPriceTracker" \
    -target x86_64-apple-macosx13.0 \
    -framework Cocoa \
    -framework Foundation \
    main.swift \
    AppDelegate.swift

if [ $? -ne 0 ]; then
    echo "❌ Swift compilation failed"
    exit 1
fi

echo "🎨 Adding app icon..."

# Build a proper .icns from the app icon set if possible
ICONSET_TEMP_DIR="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$APP_BUNDLE/Contents/Resources"

if command -v iconutil >/dev/null 2>&1; then
    mkdir -p "$ICONSET_TEMP_DIR"
    # Copy existing app icon PNGs into an .iconset folder
    cp Assets.xcassets/AppIcon.appiconset/icon_*.png "$ICONSET_TEMP_DIR" 2>/dev/null || true
    if [ -n "$(ls -1 "$ICONSET_TEMP_DIR"/icon_*.png 2>/dev/null)" ]; then
        iconutil -c icns "$ICONSET_TEMP_DIR" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns" || true
    fi
fi

# Fallback: if no .icns produced, at least copy a large PNG
if [ ! -f "$APP_BUNDLE/Contents/Resources/AppIcon.icns" ]; then
    if [ -f "Assets.xcassets/AppIcon.appiconset/icon_512x512.png" ]; then
        cp "Assets.xcassets/AppIcon.appiconset/icon_512x512.png" "$APP_BUNDLE/Contents/Resources/AppIcon.png"
    else
        echo "⚠️  App icon not found, creating placeholder..."
        python3 -c "
from PIL import Image, ImageDraw
img = Image.new('RGB', (512, 512), '#444')
draw = ImageDraw.Draw(img)
draw.text((200, 230), 'APP', fill='white')
img.save('$APP_BUNDLE/Contents/Resources/AppIcon.png')
" 2>/dev/null || true
    fi
fi

# Set executable permissions
chmod +x "$APP_BUNDLE/Contents/MacOS/BitcoinPriceTracker"

echo "📦 Copying to dist folder..."

# Copy to dist folder
cp -R "$APP_BUNDLE" "$DIST_DIR/"

echo "✅ Build completed successfully!"
echo "📁 App location: ${DIST_DIR}/${APP_NAME}.app"
echo "📊 App size:"
du -sh "${DIST_DIR}/${APP_NAME}.app"

echo ""
echo "🎯 Test the app:"
echo "  open '${DIST_DIR}/${APP_NAME}.app'"
echo ""
echo "📦 Ready for installer creation!"
