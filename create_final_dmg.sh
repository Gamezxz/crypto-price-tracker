#!/bin/bash

# Create final DMG installer using the compiled app
set -e

APP_NAME="Bitcoin Price Tracker"
DMG_NAME="Bitcoin-Price-Tracker-Installer"
TEMP_DIR="temp_dmg"
DIST_DIR="dist"

echo "🎬 Creating final DMG installer with real app..."

# Check if app exists
if [ ! -d "$DIST_DIR/${APP_NAME}.app" ]; then
    echo "❌ App not found! Run ./build_with_swiftc.sh first"
    exit 1
fi

# Clean and create temp directory
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Copy the real app
cp -R "$DIST_DIR/${APP_NAME}.app" "$TEMP_DIR/"

echo "🎨 Creating DMG background..."

# Create background image for DMG
python3 << 'EOF'
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
        font = ImageFont.truetype('/System/Library/Fonts/Helvetica Bold.ttf', 60)
    except:
        font = None
    
    draw.text((85, 180), "₿", fill='white', font=font)
    
    # Draw instructions
    try:
        title_font = ImageFont.truetype('/System/Library/Fonts/Helvetica Bold.ttf', 24)
        text_font = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttf', 16)
    except:
        title_font = None
        text_font = None
    
    draw.text((220, 160), "Bitcoin Price Tracker", fill='#333333', font=title_font)
    draw.text((220, 200), "Drag the app to Applications folder", fill='#666666', font=text_font)
    draw.text((220, 225), "to install and then launch it!", fill='#666666', font=text_font)
    
    # Draw arrow
    draw.polygon([(350, 280), (380, 295), (350, 310)], fill='#F7931A')
    draw.line([(380, 295), (450, 295)], fill='#F7931A', width=3)
    
    img.save('temp_dmg/dmg_background.png')
    print("✅ Created DMG background image")

if __name__ == "__main__":
    create_dmg_background()
EOF

echo "📦 Creating beautiful DMG installer..."

# Remove old DMG if exists
rm -f "${DIST_DIR}/${DMG_NAME}.dmg"

# Create the DMG
create-dmg \
    --volname "Bitcoin Price Tracker Installer" \
    --background "$TEMP_DIR/dmg_background.png" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 80 \
    --icon "${APP_NAME}.app" 120 200 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 480 200 \
    --eula "LICENSE" \
    "${DIST_DIR}/${DMG_NAME}.dmg" \
    "$TEMP_DIR/" || {
    
    # Fallback: create simple DMG
    echo "⚠️  Using simple DMG creation..."
    hdiutil create -volname "Bitcoin Price Tracker Installer" \
        -srcfolder "$TEMP_DIR" \
        -ov -format UDZO \
        "${DIST_DIR}/${DMG_NAME}.dmg"
}

echo "🧹 Cleaning up..."
rm -rf "$TEMP_DIR"

echo "✅ Final DMG installer created successfully!"
echo "📁 Location: ${DIST_DIR}/${DMG_NAME}.dmg"
echo "📊 File size:"
ls -lh "${DIST_DIR}/${DMG_NAME}.dmg"

echo ""
echo "🎉 Ready to distribute!"
echo "📥 Users can:"
echo "  1. Download ${DMG_NAME}.dmg"
echo "  2. Double-click to open"
echo "  3. Drag app to Applications"
echo "  4. Launch and enjoy Bitcoin prices!"
echo ""
echo "📍 Full path: $(pwd)/dist/${DMG_NAME}.dmg"