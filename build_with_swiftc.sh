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
            <key>stream.binance.com</key>
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

# Copy app icon if available
if [ -f "Assets.xcassets/AppIcon.appiconset/icon_512x512.png" ]; then
    cp "Assets.xcassets/AppIcon.appiconset/icon_512x512.png" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
else
    echo "⚠️  App icon not found, creating placeholder..."
    # Create a simple placeholder icon
    python3 -c "
from PIL import Image, ImageDraw
img = Image.new('RGB', (512, 512), '#F7931A')
draw = ImageDraw.Draw(img)
draw.ellipse([50, 50, 462, 462], fill='#F7931A', outline='#E6851F', width=10)
draw.text((220, 220), '₿', fill='white')
img.save('$APP_BUNDLE/Contents/Resources/AppIcon.png')
" 2>/dev/null || echo "Could not create icon"
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