#!/bin/bash

# Bitcoin Price Tracker Installer Creator
# Creates a beautiful DMG file with drag-and-drop installation

set -e

PROJECT_NAME="BitcoinPriceStatusBar"
APP_NAME="Bitcoin Price Tracker"
DMG_NAME="Bitcoin-Price-Tracker-Installer"
BUILD_DIR="build"
DIST_DIR="dist"
TEMP_DIR="temp_dmg"

echo "🚀 Creating installer for Bitcoin Price Tracker..."

# Clean and create directories
rm -rf "$BUILD_DIR" "$DIST_DIR" "$TEMP_DIR"
mkdir -p "$DIST_DIR" "$TEMP_DIR"

echo "📦 Building the app..."

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

echo "✅ App built successfully: $BUILT_APP"

# Copy app to temp directory
cp -R "$BUILT_APP" "$TEMP_DIR/"

# Create background image for DMG
cat > "$TEMP_DIR/create_bg.py" << 'EOF'
#!/usr/bin/env python3
from PIL import Image, ImageDraw, ImageFont
import os

def create_dmg_background():
    # Create 600x400 background
    img = Image.new('RGB', (600, 400), '#f8f9fa')
    draw = ImageDraw.Draw(img)
    
    # Draw gradient background
    for i in range(400):
        color = int(248 - (i * 0.1))
        draw.line([(0, i), (600, i)], fill=(color, color + 2, color + 5))
    
    # Draw Bitcoin logo area
    draw.ellipse([50, 150, 150, 250], fill='#F7931A', outline='#E6851F', width=3)
    
    # Draw Bitcoin symbol
    try:
        font = ImageFont.truetype('/System/Library/Fonts/Arial Bold.ttf', 60)
    except:
        font = ImageFont.load_default()
    
    draw.text((85, 180), "₿", fill='white', font=font)
    
    # Draw instructions
    try:
        title_font = ImageFont.truetype('/System/Library/Fonts/Helvetica Bold.ttf', 24)
        text_font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttf', 16)
    except:
        title_font = ImageFont.load_default()
        text_font = ImageFont.load_default()
    
    draw.text((220, 160), "Bitcoin Price Tracker", fill='#333333', font=title_font)
    draw.text((220, 200), "Drag the app to Applications folder", fill='#666666', font=text_font)
    draw.text((220, 225), "to install and then launch it!", fill='#666666', font=text_font)
    
    # Draw arrow
    draw.polygon([(350, 280), (380, 295), (350, 310)], fill='#F7931A')
    draw.line([(380, 295), (450, 295)], fill='#F7931A', width=3)
    
    img.save('dmg_background.png')
    print("Created DMG background image")

if __name__ == "__main__":
    create_dmg_background()
EOF

# Create background image
cd "$TEMP_DIR"
python3 create_bg.py
cd ..

echo "🎨 Creating beautiful DMG installer..."

# Create the DMG
create-dmg \
    --volname "${APP_NAME} Installer" \
    --volicon "Assets.xcassets/AppIcon.appiconset/icon_512x512.png" \
    --background "$TEMP_DIR/dmg_background.png" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 80 \
    --icon "${APP_NAME}.app" 120 200 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 480 200 \
    --eula "LICENSE" \
    "${DIST_DIR}/${DMG_NAME}.dmg" \
    "$TEMP_DIR/"

echo "🧹 Cleaning up..."
rm -rf "$TEMP_DIR"

echo "✅ Installer created successfully!"
echo "📁 Location: ${DIST_DIR}/${DMG_NAME}.dmg"
echo "📊 File size:"
ls -lh "${DIST_DIR}/${DMG_NAME}.dmg"

echo ""
echo "🎉 Installation instructions for users:"
echo "1. Download ${DMG_NAME}.dmg"
echo "2. Double-click to open the installer"
echo "3. Drag 'Bitcoin Price Tracker' to Applications folder"
echo "4. Launch from Applications or Spotlight"
echo "5. Enjoy live Bitcoin prices in your status bar!"