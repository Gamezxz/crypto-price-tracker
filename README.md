# 🪙 Crypto Price Tracker

A beautiful macOS status bar application that displays real-time prices for top 30 cryptocurrencies.

## 🖼️ Screenshot

![Crypto Price Tracker Screenshot](new_ss.png)

## ✨ Features

- **🔴 Real-time price updates** - Live prices for 30 cryptocurrencies from Binance
- **⚡ WebSocket connection** - Ultra-fast price updates via Spot & Futures streams
- **🔄 Auto-reconnection** - Never miss a price change
- **🎨 Clean interface** - Minimal and elegant status bar design with coin icons
- **📊 24h change tracking** - See percentage changes at a glance
- **🪙 Multi-select display** - Show up to 10 coins simultaneously in the status bar
- **💰 Formatted prices** - Smart decimal formatting based on price magnitude

## 📋 Requirements

- **macOS 13.0+** (Ventura or later)
- **Internet connection** for live price data
- **~5MB disk space**

## 🚀 Quick Start

### Option 1: Download Ready-to-Use App
1. Download the latest release from GitHub
2. Unzip the file
3. Right-click on "Crypto Price Tracker.app" → "Open"
4. Enjoy live crypto prices in your status bar!

### Option 2: Build from Source
1. Clone this repository
2. Open `BitcoinPriceStatusBar.xcodeproj` in Xcode
3. Select your development team
4. Press ⌘+R to build and run

## 🔨 Building for Distribution

```bash
# Run the build script
./build.sh

# Your app will be in the 'dist' folder
```

## Supported Cryptocurrencies

BTC, ETH, BNB, XRP, SOL, DOGE, ADA, TRX, LINK, AVAX, DOT, SUI, HYPE, PAXG, LTC, NEAR, APT, ARB, OP, UNI, ATOM, AAVE, XLM, HBAR, FIL, INJ, PEPE, BCH, ETC, ASTER

## How to Use

1. Launch the app
2. The selected cryptocurrency price will appear in your status bar
3. Click on the status bar item to see the menu:
   - **All Cryptocurrencies** - Browse and select coins to display
   - **Reconnect** - Reconnect WebSocket streams
   - **About** - App info
   - **Quit** - Exit the app
4. Select up to 10 coins to display simultaneously in the status bar

## API

This app uses the **Binance WebSocket API** for real-time price updates:
- Spot: `wss://stream.binance.com:9443/stream?streams=...`
- Futures: `wss://fstream.binance.com/stream?streams=...`
- Coin icons from CoinMarketCap
- No API key required
- Automatic reconnection on connection loss

## License

MIT License
