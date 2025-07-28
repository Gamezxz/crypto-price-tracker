#!/bin/bash

# Simple Installation Script for Bitcoin Price Tracker
# This script will be included in the DMG for one-click installation

set -e

APP_NAME="Bitcoin Price Tracker"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "🪙 Installing Bitcoin Price Tracker..."

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This app is only compatible with macOS"
    exit 1
fi

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
REQUIRED_VERSION="13.0"

if [[ "$(printf '%s\n' "$REQUIRED_VERSION" "$MACOS_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]]; then
    echo "❌ This app requires macOS 13.0 or later. You have $MACOS_VERSION"
    exit 1
fi

echo "✅ macOS version check passed"

# Check if Applications directory exists
if [ ! -d "/Applications" ]; then
    echo "❌ Applications directory not found"
    exit 1
fi

# Copy app to Applications
if [ -d "$SCRIPT_DIR/${APP_NAME}.app" ]; then
    echo "📁 Copying app to Applications folder..."
    
    # Remove existing app if present
    if [ -d "/Applications/${APP_NAME}.app" ]; then
        echo "🗑️  Removing existing installation..."
        rm -rf "/Applications/${APP_NAME}.app"
    fi
    
    # Copy new app
    cp -R "$SCRIPT_DIR/${APP_NAME}.app" "/Applications/"
    
    echo "✅ Installation completed!"
    echo ""
    echo "🎉 Bitcoin Price Tracker has been installed successfully!"
    echo ""
    echo "📍 You can now:"
    echo "  1. Find it in Applications folder"
    echo "  2. Search for it in Spotlight (⌘+Space)"
    echo "  3. Launch it to see Bitcoin prices in your status bar"
    echo ""
    
    # Ask if user wants to launch now
    read -p "🚀 Would you like to launch Bitcoin Price Tracker now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔓 You may need to allow the app in System Preferences > Security & Privacy"
        open "/Applications/${APP_NAME}.app"
    fi
    
else
    echo "❌ App not found in installer package"
    exit 1
fi

echo ""
echo "💡 Tip: The app runs in your status bar. Look for the ₿ symbol!"