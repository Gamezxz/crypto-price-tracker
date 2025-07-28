#!/bin/bash

# Quick test script to verify everything works
echo "🧪 Testing Bitcoin Price Tracker installer creation..."

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from App Store."
    exit 1
fi

# Check create-dmg
if ! command -v create-dmg &> /dev/null; then
    echo "⚠️  create-dmg not found. Installing..."
    brew install create-dmg
fi

# Check Python and Pillow
if ! python3 -c "from PIL import Image" &> /dev/null; then
    echo "⚠️  Pillow not found. Installing..."
    pip3 install Pillow
fi

echo "✅ All prerequisites met!"

# Test simple build first
echo "🔨 Testing simple build..."
if xcodebuild -project "BitcoinPriceStatusBar.xcodeproj" -scheme "BitcoinPriceStatusBar" -configuration Release -derivedDataPath "build_test" BUILD_DIR="build_test/Build/Products" ONLY_ACTIVE_ARCH=NO &> /dev/null; then
    echo "✅ Build test successful!"
    rm -rf build_test
else
    echo "❌ Build test failed. Check your Xcode project."
    exit 1
fi

# Test installer creation
echo "📦 Testing installer creation..."
if ./create_installer.sh &> installer_test.log; then
    echo "✅ DMG installer created successfully!"
    ls -lh dist/
else
    echo "❌ DMG installer creation failed. Check installer_test.log"
    cat installer_test.log
    exit 1
fi

echo ""
echo "🎉 All tests passed! Your installer is ready to distribute."
echo ""
echo "📁 Available files in dist/:"
ls -la dist/
echo ""
echo "🚀 Ready to share:"
echo "  • DMG file for easy installation"
echo "  • Professional-looking installer"
echo "  • Ready for distribution!"