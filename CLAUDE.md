# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Crypto Price Tracker is a macOS status bar application that displays real-time cryptocurrency prices from the Binance WebSocket API. The app supports multiple cryptocurrencies including Bitcoin (BTC), Ethereum (ETH), BNB, Cardano (ADA), Solana (SOL), Polkadot (DOT), Chainlink (LINK), and Avalanche (AVAX). The app is built in Swift using Cocoa framework and consists of two main Swift files in a simple architecture.

## Key Build Commands

### Building the Application
```bash
# Full Xcode build for distribution
./build.sh

# Direct Swift compilation (without Xcode)
./build_with_swiftc.sh

# Quick build test
./quick_test.sh
```

### Creating Installers
```bash
# Create DMG installer
./create_installer.sh

# Create PKG installer  
./create_pkg_installer.sh

# Create sample DMG
./create_sample_dmg.sh

# Create final DMG with custom styling
./create_final_dmg.sh
```

### Testing
```bash
# Test all build processes
./quick_test.sh

# Manual app testing
open "dist/Bitcoin Price Tracker.app"
```

## Architecture

### Core Components
- **main.swift**: Entry point that initializes NSApplication and AppDelegate
- **AppDelegate.swift**: Main application logic containing:
  - Multi-cryptocurrency data management
  - Status bar management with currency selection
  - WebSocket connection handling for multiple streams
  - Cryptocurrency price fetching and display
  - Menu system with currency switching and price display

### Key Classes and Methods
- `CryptoCurrency`: Data structure for cryptocurrency information (symbol, name, emoji, price, lastUpdate)
- `AppDelegate`: Main controller class
  - `initializeCryptocurrencies()`: Initializes supported cryptocurrency list
  - `setupStatusBar()`: Creates status bar item and menu with multi-currency support
  - `connectToWebSocket()`: Establishes multi-stream Binance WebSocket connection
  - `fetchInitialPrices()`: Gets initial prices for all cryptocurrencies via REST API
  - `selectCryptocurrency()`: Handles currency selection from menu
  - `updateUI()`: Updates status bar and menu with current prices
  - `updateStatusBarForSelectedCrypto()`: Updates status bar for currently selected crypto
  - `updateMenuPrices()`: Updates all cryptocurrency prices in submenu

### Data Flow
1. App launches and initializes supported cryptocurrencies (BTC, ETH, BNB, ADA, SOL, DOT, LINK, AVAX)
2. Sets up status bar with selected cryptocurrency (defaults to Bitcoin)
3. Fetches initial prices for all cryptocurrencies from Binance REST API
4. Establishes multi-stream WebSocket connection to Binance for real-time updates
5. Processes incoming price data for each cryptocurrency and updates UI
6. User can select different cryptocurrencies from "All Cryptocurrencies" submenu
7. Auto-reconnects on connection failures

### WebSocket Integration
- **Endpoint**: `wss://stream.binance.com:9443/stream?streams=btcusdt@ticker/ethusdt@ticker/bnbusdt@ticker/adausdt@ticker/solusdt@ticker/dotusdt@ticker/linkusdt@ticker/avaxusdt@ticker`
- **Multi-stream format**: Handles stream-specific data with `stream` and `data` fields
- **Price field**: Uses `c` field from ticker data (current price)
- **Symbol extraction**: Extracts currency symbol from stream name
- **Auto-reconnection**: 5-second delay on connection failures

## Project Structure

### Build Outputs
- `build/`: Xcode build artifacts
- `build_swift/`: Swift compiler build output  
- `dist/`: Final distribution files
- `pkg_temp/`: Temporary PKG installer files

### Configuration Files
- `Info.plist`: Main app configuration
- `Info-Debug.plist`: Debug build configuration
- `ExportOptions.plist`: Xcode export settings
- `BitcoinPriceStatusBar.xcodeproj/`: Xcode project file

### Build Requirements
- **macOS 13.0+** (deployment target)
- **Xcode** with Swift 5.0+
- **create-dmg** (install via `brew install create-dmg`)
- **Python 3 with Pillow** (for icon generation)

### App Naming
- **Bundle ID**: com.crypto.pricetracker (updated from com.bitcoin.pricetracker)
- **Display Name**: "Crypto Price Tracker" (updated from "Bitcoin Price Tracker")
- **Internal Project**: Still uses "BitcoinPriceStatusBar" for backwards compatibility

## Development Notes

### Supported Cryptocurrencies
- **Bitcoin (BTC)**: ₿ emoji, BTCUSDT symbol
- **Ethereum (ETH)**: Ξ emoji, ETHUSDT symbol  
- **BNB**: 🔸 emoji, BNBUSDT symbol
- **Cardano (ADA)**: 🅰️ emoji, ADAUSDT symbol
- **Solana (SOL)**: ◎ emoji, SOLUSDT symbol
- **Polkadot (DOT)**: 🔴 emoji, DOTUSDT symbol
- **Chainlink (LINK)**: 🔗 emoji, LINKUSDT symbol
- **Avalanche (AVAX)**: 🔺 emoji, AVAXUSDT symbol

### Status Bar Application Pattern
This is a menu bar app (LSUIElement = true) with no dock icon. The app lives entirely in the status bar and provides a dropdown menu for cryptocurrency selection and price viewing. The status bar displays the currently selected cryptocurrency with its emoji and price.

### Multi-Currency Architecture
The app uses a `CryptoCurrency` struct to manage multiple currencies and maintains a dictionary of all supported cryptocurrencies. Users can switch between currencies using the "All Cryptocurrencies" submenu, with the selected currency marked with a checkmark.

### WebSocket Reliability
The app implements robust WebSocket handling with automatic reconnection, initial REST API fallback for all currencies, and error handling for network issues. The multi-stream WebSocket connection efficiently receives updates for all supported cryptocurrencies simultaneously.

### Price Formatting
Uses NumberFormatter with comma separators and 2 decimal places for consistent price display across status bar and menu items. Each cryptocurrency displays with its unique emoji for easy identification.