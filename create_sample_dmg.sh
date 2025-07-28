#!/bin/bash

# Create a sample DMG to demonstrate the installer format
set -e

APP_NAME="Bitcoin Price Tracker"
DMG_NAME="Bitcoin-Price-Tracker-Installer"
TEMP_DIR="temp_dmg"
DIST_DIR="dist"

echo "🎬 Creating sample DMG installer..."

# Clean and create directories
rm -rf "$TEMP_DIR" "$DIST_DIR"
mkdir -p "$TEMP_DIR" "$DIST_DIR"

# Create a sample app bundle structure
APP_BUNDLE="$TEMP_DIR/${APP_NAME}.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>BitcoinPriceTracker</string>
    <key>CFBundleIdentifier</key>
    <string>com.bitcoin.pricetracker</string>
    <key>CFBundleName</key>
    <string>Bitcoin Price Tracker</string>
    <key>CFBundleDisplayName</key>
    <string>Bitcoin Price Tracker</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Create executable script
cat > "$APP_BUNDLE/Contents/MacOS/BitcoinPriceTracker" << 'EOF'
#!/bin/bash
echo "🪙 Bitcoin Price Tracker starting..."
echo "This is a sample app bundle for demonstration."
echo "The real app would connect to Binance WebSocket and show Bitcoin prices."
EOF

chmod +x "$APP_BUNDLE/Contents/MacOS/BitcoinPriceTracker"

# Copy app icon
cp "Assets.xcassets/AppIcon.appiconset/icon_512x512.png" "$APP_BUNDLE/Contents/Resources/AppIcon.png" 2>/dev/null || {
    echo "ℹ️  Creating sample icon..."
    # Create a simple icon if original doesn't exist
    python3 -c "
from PIL import Image, ImageDraw
img = Image.new('RGB', (512, 512), '#F7931A')
draw = ImageDraw.Draw(img)
draw.ellipse([50, 50, 462, 462], fill='#F7931A', outline='#E6851F', width=10)
draw.text((200, 220), '₿', fill='white', font=None)
img.save('$APP_BUNDLE/Contents/Resources/AppIcon.png')
" 2>/dev/null || echo "Could not create icon"
}

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

echo "📦 Creating DMG installer..."

# Create the DMG
create-dmg \
    --volname "Bitcoin Price Tracker Installer" \
    --volicon "Assets.xcassets/AppIcon.appiconset/icon_512x512.png" \
    --background "$TEMP_DIR/dmg_background.png" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 80 \
    --icon "${APP_NAME}.app" 120 200 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 480 200 \
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

echo "✅ Sample DMG installer created successfully!"
echo "📁 Location: ${DIST_DIR}/${DMG_NAME}.dmg"
echo "📊 File size:"
ls -lh "${DIST_DIR}/${DMG_NAME}.dmg"

echo ""
echo "🎉 DMG installer ready!"
echo "📥 Users can now:"
echo "  1. Download ${DMG_NAME}.dmg"
echo "  2. Double-click to open"
echo "  3. Drag app to Applications"
echo "  4. Launch and enjoy!"
echo ""
echo "📍 File location: $(pwd)/dist/${DMG_NAME}.dmg"