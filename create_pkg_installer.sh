#!/bin/bash

# Creates a PKG installer for Bitcoin Price Tracker
# This provides an alternative installation method

set -e

PROJECT_NAME="BitcoinPriceStatusBar"
APP_NAME="Bitcoin Price Tracker"
PKG_NAME="Bitcoin-Price-Tracker-Installer"
BUILD_DIR="build"
DIST_DIR="dist"
PKG_DIR="pkg_temp"

echo "📦 Creating PKG installer for Bitcoin Price Tracker..."

# Clean and create directories
rm -rf "$PKG_DIR" 
mkdir -p "$DIST_DIR" "$PKG_DIR/Applications"

echo "🔨 Building the app..."

# Build the app for release
xcodebuild -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "$PROJECT_NAME" \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    BUILD_DIR="$BUILD_DIR/Build/Products" \
    ONLY_ACTIVE_ARCH=NO

# Find the built app
BUILT_APP=$(find "$BUILD_DIR" -name "*.app" -type d | head -1)

if [ ! -d "$BUILT_APP" ]; then
    echo "❌ Could not find built app!"
    exit 1
fi

echo "✅ App built successfully"

# Copy app to package directory
cp -R "$BUILT_APP" "$PKG_DIR/Applications/"

# Create postinstall script
mkdir -p "$PKG_DIR/Scripts"
cat > "$PKG_DIR/Scripts/postinstall" << 'EOF'
#!/bin/bash

# Post-installation script for Bitcoin Price Tracker

echo "🎉 Bitcoin Price Tracker installed successfully!"

# Make sure the app has correct permissions
chmod -R 755 "/Applications/Bitcoin Price Tracker.app"

# Create a launch agent plist if user wants auto-start (optional)
USER_HOME=$(dscl . -read /Users/$(stat -f%Su /dev/console) NFSHomeDirectory | awk '{print $2}')

# Show installation success message
/usr/bin/osascript << EOD
display dialog "🪙 Bitcoin Price Tracker has been installed successfully!

You can now:
• Find it in Applications folder
• Search for it in Spotlight (⌘+Space)
• Launch it to see live Bitcoin prices in your status bar

Look for the ₿ symbol in your status bar!" buttons {"OK"} default button 1 with title "Installation Complete"
EOD

exit 0
EOF

chmod +x "$PKG_DIR/Scripts/postinstall"

# Create package info
cat > "$PKG_DIR/PackageInfo" << EOF
<?xml version="1.0" encoding="utf-8"?>
<pkg-info format-version="2" identifier="com.bitcoin.pricetracker.pkg" version="1.0.0" install-location="/" auth="root">
    <payload installKBytes="$(du -k "$PKG_DIR/Applications" | tail -1 | awk '{print $1}')" numberOfFiles="$(find "$PKG_DIR/Applications" | wc -l | tr -d ' ')"/>
    <scripts>
        <postinstall file="./Scripts/postinstall"/>
    </scripts>
</pkg-info>
EOF

echo "📋 Creating package..."

# Build the package
pkgbuild \
    --root "$PKG_DIR/Applications" \
    --scripts "$PKG_DIR/Scripts" \
    --identifier "com.bitcoin.pricetracker.pkg" \
    --version "1.0.0" \
    --install-location "/Applications" \
    "${DIST_DIR}/${PKG_NAME}.pkg"

# Create product archive (for distribution)
productbuild \
    --package "${DIST_DIR}/${PKG_NAME}.pkg" \
    --distribution "distribution.xml" \
    "${DIST_DIR}/${PKG_NAME}-Final.pkg" 2>/dev/null || {
    
    # If productbuild fails, use the simple pkg
    echo "ℹ️  Using simple PKG format"
    mv "${DIST_DIR}/${PKG_NAME}.pkg" "${DIST_DIR}/${PKG_NAME}-Final.pkg"
}

echo "🧹 Cleaning up..."
rm -rf "$PKG_DIR"

echo "✅ PKG installer created successfully!"
echo "📁 Location: ${DIST_DIR}/${PKG_NAME}-Final.pkg"
echo "📊 File size:"
ls -lh "${DIST_DIR}/${PKG_NAME}-Final.pkg"

echo ""
echo "🎯 Installation instructions for users:"
echo "1. Download ${PKG_NAME}-Final.pkg"
echo "2. Double-click to run the installer"
echo "3. Follow the installation wizard"
echo "4. App will be installed to Applications folder"
echo "5. Launch and enjoy!"