# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Crypto Price Tracker is a macOS status bar application that displays real-time cryptocurrency prices from the Binance WebSocket API. The app tracks the top 30 cryptocurrencies with live price streaming via both Spot and Futures WebSocket connections. Users can select up to 10 coins to display simultaneously in the menu bar. The app is built in Swift using Cocoa framework and consists of two Swift files.

## Key Build Commands

### Building the Application
```bash
# Direct Swift compilation as Universal Binary (recommended)
./build_with_swiftc.sh

# Full Xcode build (requires Xcode)
./build.sh
```

### Creating DMG Installer
```bash
# Requires: brew install create-dmg
# After building with build_with_swiftc.sh, create DMG manually:
create-dmg --volname "Crypto Price Tracker" \
  --icon "Crypto Price Tracker.app" 150 200 \
  --app-drop-link 450 200 \
  "dist/Crypto-Price-Tracker.dmg" "dist/"
```

### Testing
```bash
open "dist/Crypto Price Tracker.app"
```

## Architecture

### Core Components
- **main.swift**: Entry point that initializes NSApplication and AppDelegate
- **AppDelegate.swift**: Main application logic containing:
  - Fixed top 30 cryptocurrency list management
  - Status bar with multi-select display (up to 10 coins)
  - Dual WebSocket connections (Spot + Futures)
  - CoinMarketCap icon downloading and caching
  - Smart price formatting with variable decimal precision

### Key Classes and Methods
- `CryptoCurrency`: Data structure (symbol, name, emoji, price, change24h, changePercent24h, lastUpdate)
- `AppDelegate`: Main controller class
  - `initializeCryptocurrencies()`: Initializes the fixed top 30 cryptocurrency list
  - `setupStatusBar()`: Creates status bar item and menu
  - `connectToWebSocket()`: Establishes Spot WebSocket connection
  - `connectToFuturesWebSocket()`: Establishes Futures WebSocket connection (for HYPE etc.)
  - `fetchInitialPrices()`: Gets initial prices via Binance REST API
  - `fetchFuturesInitialPrices()`: Gets initial prices for futures-only symbols
  - `toggleCryptocurrency()`: Toggles coin selection (multi-select, max 10)
  - `downloadAllIcons()` / `downloadCoinIcon()`: Downloads CoinMarketCap logos
  - `updateUI()`: Updates status bar and menu with current prices
  - `updateStatusBarForSelectedCrypto()`: Renders selected coins with icons in status bar
  - `updateMenuPrices()`: Updates all prices in the submenu

### Data Flow
1. App launches and initializes 30 cryptocurrencies from `fixedTopSymbols`
2. Sets up status bar (defaults to BTC selected)
3. Fetches initial prices from Binance REST API (Spot + Futures)
4. Downloads CoinMarketCap icons for all coins
5. Establishes dual WebSocket connections for real-time streaming
6. Processes incoming price/change data and updates UI
7. User can toggle up to 10 coins from "All Cryptocurrencies" submenu
8. Auto-reconnects on connection failures (5-second delay)

### WebSocket Integration
- **Spot**: `wss://stream.binance.com:9443/stream?streams=btcusdt@ticker/ethusdt@ticker/...`
- **Futures**: `wss://fstream.binance.com/stream?streams=hypeusdt@ticker/...`
- **Futures-only symbols**: `HYPEUSDT` (not available on Spot)
- **Multi-stream format**: Handles `stream` and `data` fields
- **Price fields**: `c` (current price), `P` (24h change %), `p` (24h change absolute)
- **Auto-reconnection**: 5-second delay on connection failures

## Project Structure

```
├── AppDelegate.swift          # Main app logic (30 coins, dual WebSocket, icons)
├── main.swift                 # Entry point
├── Assets.xcassets/           # App icon set (16x16 to 1024x1024)
├── BitcoinPriceStatusBar.xcodeproj/  # Xcode project
├── build.sh                   # Xcode build script
├── build_with_swiftc.sh       # Swift compiler build (Universal Binary)
├── index.html                 # Landing page (GitHub Pages)
├── logo.png                   # App logo for website
├── new_ss.png                 # App screenshot
├── README.md
├── CLAUDE.md
├── LICENSE
└── .gitignore
```

### Build Outputs (gitignored)
- `build/`: Xcode build artifacts
- `build_swift/`: Swift compiler build output
- `dist/`: Final distribution files (app bundle, DMG)

### Build Requirements
- **macOS 13.0+** (deployment target)
- **Xcode** with Swift 5.0+ (for build.sh) or just **swiftc** (for build_with_swiftc.sh)
- **create-dmg** (optional, `brew install create-dmg`) for DMG creation

### App Naming
- **Bundle ID**: com.crypto.pricetracker
- **Display Name**: "Crypto Price Tracker"
- **Internal Project**: "BitcoinPriceStatusBar" (legacy name)

## Supported Cryptocurrencies (Top 30)

BTC, ETH, BNB, XRP, SOL, DOGE, ADA, TRX, LINK, AVAX, DOT, SUI, HYPE, PAXG, LTC, NEAR, APT, ARB, OP, UNI, ATOM, AAVE, XLM, HBAR, FIL, INJ, PEPE, BCH, ETC, ASTER

Icons are fetched from CoinMarketCap using `knownCMCIds` mapping.

## Development Notes

### Status Bar Application Pattern
Menu bar app (LSUIElement = true) with no dock icon. Lives entirely in the status bar with a dropdown menu for coin selection and price viewing.

### Multi-Select Display
Users can select up to 10 coins to display simultaneously in the status bar, separated by ` | `. Each coin shows its CoinMarketCap icon, price, and 24h change percentage.

### Price Formatting
Smart decimal precision based on price magnitude:
- < $10: 4 decimal places
- < $100: 3 decimal places
- < $10,000: 2 decimal places
- >= $10,000: 1 decimal place

### Landing Page
`index.html` is a self-contained landing page deployed via GitHub Pages at https://gamezxz.github.io/crypto-price-tracker/. It fetches live prices from Binance REST API and auto-refreshes every 30 seconds. Design uses dark mode with glassmorphism (see `.claude/skills/openusage-design.md`).

### GitHub Releases
DMG installers are published at https://github.com/Gamezxz/crypto-price-tracker/releases. Built as Universal Binary (arm64 + x86_64).
