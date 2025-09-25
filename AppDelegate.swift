import Cocoa
import Foundation

struct CryptoCurrency {
    let symbol: String
    let name: String
    let emoji: String
    var price: Double
    var change24h: Double
    var changePercent24h: Double
    var lastUpdate: Date
    
    init(symbol: String, name: String, emoji: String) {
        self.symbol = symbol
        self.name = name
        self.emoji = emoji
        self.price = 0.0
        self.change24h = 0.0
        self.changePercent24h = 0.0
        self.lastUpdate = Date()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem?
    var webSocketTask: URLSessionWebSocketTask?
    var webSocketTaskFutures: URLSessionWebSocketTask?
    var cryptocurrencies: [String: CryptoCurrency] = [:]
    // Multi-select up to 3
    var selectedCryptos: [String] = ["BTCUSDT"]
    // Backward-compat: first selected as primary
    var selectedCrypto: String { selectedCryptos.first ?? "BTCUSDT" }
    var reconnectTimer: Timer?
    var reconnectTimerFutures: Timer?
    
    // Binance Futures (USD-M) symbols to track
    private let futuresSymbols: Set<String> = ["ASTERUSDT"]
    
    private let supportedCryptocurrencies = [
        // Major Cryptocurrencies
        "BTCUSDT": CryptoCurrency(symbol: "BTCUSDT", name: "Bitcoin", emoji: "₿"),
        "ETHUSDT": CryptoCurrency(symbol: "ETHUSDT", name: "Ethereum", emoji: "Ξ"),
        "BNBUSDT": CryptoCurrency(symbol: "BNBUSDT", name: "BNB", emoji: "🔸"),
        "ADAUSDT": CryptoCurrency(symbol: "ADAUSDT", name: "Cardano", emoji: "🅰️"),
        "SOLUSDT": CryptoCurrency(symbol: "SOLUSDT", name: "Solana", emoji: "◎"),
        "DOTUSDT": CryptoCurrency(symbol: "DOTUSDT", name: "Polkadot", emoji: "🔴"),
        "LINKUSDT": CryptoCurrency(symbol: "LINKUSDT", name: "Chainlink", emoji: "🔗"),
        "AVAXUSDT": CryptoCurrency(symbol: "AVAXUSDT", name: "Avalanche", emoji: "🔺"),
        
        // Top Volume Cryptocurrencies
        "XRPUSDT": CryptoCurrency(symbol: "XRPUSDT", name: "XRP", emoji: "💧"),
        "LTCUSDT": CryptoCurrency(symbol: "LTCUSDT", name: "Litecoin", emoji: "🪙"),
        "MATICUSDT": CryptoCurrency(symbol: "MATICUSDT", name: "Polygon", emoji: "🔷"),
        "TRXUSDT": CryptoCurrency(symbol: "TRXUSDT", name: "TRON", emoji: "🔺"),
        "ATOMUSDT": CryptoCurrency(symbol: "ATOMUSDT", name: "Cosmos", emoji: "⚛️"),
        "UNIUSDT": CryptoCurrency(symbol: "UNIUSDT", name: "Uniswap", emoji: "🦄"),
        "XLMUSDT": CryptoCurrency(symbol: "XLMUSDT", name: "Stellar", emoji: "⭐"),
        "VETUSDT": CryptoCurrency(symbol: "VETUSDT", name: "VeChain", emoji: "⚡"),
        "ICPUSDT": CryptoCurrency(symbol: "ICPUSDT", name: "Internet Computer", emoji: "∞"),
        "FILUSDT": CryptoCurrency(symbol: "FILUSDT", name: "Filecoin", emoji: "📁"),
        "ALGOUSDT": CryptoCurrency(symbol: "ALGOUSDT", name: "Algorand", emoji: "🔺"),
        "HBARUSDT": CryptoCurrency(symbol: "HBARUSDT", name: "Hedera", emoji: "🌀"),
        "NEARUSDT": CryptoCurrency(symbol: "NEARUSDT", name: "NEAR Protocol", emoji: "🔮"),
        "APTUSDT": CryptoCurrency(symbol: "APTUSDT", name: "Aptos", emoji: "🚀"),
        "OPUSDT": CryptoCurrency(symbol: "OPUSDT", name: "Optimism", emoji: "🔴"),
        "ARBUSDT": CryptoCurrency(symbol: "ARBUSDT", name: "Arbitrum", emoji: "🔵"),
        "SUIUSDT": CryptoCurrency(symbol: "SUIUSDT", name: "Sui", emoji: "🌊"),
        "INJUSDT": CryptoCurrency(symbol: "INJUSDT", name: "Injective", emoji: "💉"),
        "MANAUSDT": CryptoCurrency(symbol: "MANAUSDT", name: "Decentraland", emoji: "🏗️"),
        "SANDUSDT": CryptoCurrency(symbol: "SANDUSDT", name: "The Sandbox", emoji: "🏖️"),
        "THETAUSDT": CryptoCurrency(symbol: "THETAUSDT", name: "Theta", emoji: "📺"),
        "AXSUSDT": CryptoCurrency(symbol: "AXSUSDT", name: "Axie Infinity", emoji: "🎮"),
        "AAVEUSDT": CryptoCurrency(symbol: "AAVEUSDT", name: "Aave", emoji: "👻"),
        "COMPUSDT": CryptoCurrency(symbol: "COMPUSDT", name: "Compound", emoji: "🏛️"),
        "MKRUSDT": CryptoCurrency(symbol: "MKRUSDT", name: "Maker", emoji: "🎯"),
        "CRVUSDT": CryptoCurrency(symbol: "CRVUSDT", name: "Curve", emoji: "〰️"),
        "SUSHIUSDT": CryptoCurrency(symbol: "SUSHIUSDT", name: "SushiSwap", emoji: "🍣"),
        "1INCHUSDT": CryptoCurrency(symbol: "1INCHUSDT", name: "1inch", emoji: "📏"),
        "LRCUSDT": CryptoCurrency(symbol: "LRCUSDT", name: "Loopring", emoji: "🔄"),
        "ENJUSDT": CryptoCurrency(symbol: "ENJUSDT", name: "Enjin", emoji: "🎨"),
        // Futures: ASTER (USDⓂ perpetual)
        "ASTERUSDT": CryptoCurrency(symbol: "ASTERUSDT", name: "ASTER", emoji: "🌟"),
        // Added: Astar (ASTER)
        // Binance symbol: ASTRUSDT
        "ASTRUSDT": CryptoCurrency(symbol: "ASTRUSDT", name: "Astar", emoji: "✨")
    ]
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("🚀 App launched successfully!")
        initializeCryptocurrencies()
        setupStatusBar()
        print("📊 Status bar setup complete")
        fetchInitialPrices()
        print("💰 Fetching initial prices...")
        connectToWebSocket() // Spot
        connectToFuturesWebSocket() // Futures
        print("🔌 Connecting to WebSocket...")
    }
    
    private func initializeCryptocurrencies() {
        cryptocurrencies = supportedCryptocurrencies
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTaskFutures?.cancel(with: .goingAway, reason: nil)
        reconnectTimer?.invalidate()
        reconnectTimerFutures?.invalidate()
    }
    
    private func setupStatusBar() {
        print("🔧 Setting up status bar...")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            let emojis = selectedCryptos.prefix(3).compactMap { cryptocurrencies[$0]?.emoji }.joined(separator: " ")
            let prefix = emojis.isEmpty ? "₿" : emojis
            button.title = "\(prefix) Loading..."
            button.target = self
            button.action = #selector(statusBarButtonClicked)
            print("✅ Status bar button created with title: \(button.title)")
        } else {
            print("❌ Failed to create status bar button!")
        }
        
        setupMenu()
        print("✅ Status bar setup completed")
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // Current selected currencies summary
        let summaryTitle = selectedCryptos.isEmpty ? "Selected: None" : "Selected: \(selectedCryptos.joined(separator: ", "))"
        let currentPriceItem = NSMenuItem(title: summaryTitle, action: nil, keyEquivalent: "")
        currentPriceItem.tag = 100
        menu.addItem(currentPriceItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // All cryptocurrencies submenu
        let allCryptosItem = NSMenuItem(title: "All Cryptocurrencies", action: nil, keyEquivalent: "")
        let allCryptosMenu = NSMenu()
        
        // Add menu items for each cryptocurrency
        for (symbol, crypto) in supportedCryptocurrencies.sorted(by: { $0.key < $1.key }) {
            let cryptoItem = NSMenuItem(title: "\(crypto.emoji) \(crypto.name): Loading...", action: #selector(toggleCryptocurrency(_:)), keyEquivalent: "")
            cryptoItem.target = self
            cryptoItem.tag = symbol.hashValue
            cryptoItem.representedObject = symbol
            allCryptosMenu.addItem(cryptoItem)
        }
        
        allCryptosItem.submenu = allCryptosMenu
        menu.addItem(allCryptosItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let connectionItem = NSMenuItem(title: "Reconnect", action: #selector(reconnectWebSocket), keyEquivalent: "r")
        connectionItem.target = self
        menu.addItem(connectionItem)
        
        let aboutItem = NSMenuItem(title: "About", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc func toggleCryptocurrency(_ sender: NSMenuItem) {
        guard let symbol = sender.representedObject as? String else { return }
        if let idx = selectedCryptos.firstIndex(of: symbol) {
            selectedCryptos.remove(at: idx)
        } else {
            if selectedCryptos.count >= 3 {
                let alert = NSAlert()
                alert.messageText = "Selection limit reached"
                alert.informativeText = "You can select up to 3 currencies."
                alert.alertStyle = .warning
                alert.runModal()
            } else {
                selectedCryptos.append(symbol)
            }
        }
        updateStatusBarForSelectedCrypto()
        updateMenuPrices()
        connectToWebSocket() // Reconnect Spot
        connectToFuturesWebSocket() // Reconnect Futures
    }
    
    @objc func statusBarButtonClicked() {
        // Menu will show automatically
    }
    
    @objc func reconnectWebSocket() {
        print("Manual reconnect requested")
        fetchInitialPrices()
        connectToWebSocket()
        connectToFuturesWebSocket()
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Crypto Price Monitor"
        let cryptoCount = supportedCryptocurrencies.count
        alert.informativeText = "A comprehensive app to monitor cryptocurrency prices in the status bar.\n\nSupports \(cryptoCount) cryptocurrencies including:\nBTC, ETH, BNB, ADA, SOL, XRP, LTC, MATIC, and many more!\n\nReal-time data from Binance WebSocket API"
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    private func fetchInitialPrices() {
        // Fetch 24hr ticker data for all supported cryptocurrencies
        guard let url = URL(string: "https://api.binance.com/api/v3/ticker/24hr") else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                print("Error fetching initial prices: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    DispatchQueue.main.async {
                        for item in jsonArray {
                            if let symbol = item["symbol"] as? String,
                               let priceString = item["lastPrice"] as? String,
                               let price = Double(priceString),
                               self.supportedCryptocurrencies[symbol] != nil {
                                
                                // Extract 24hr change data
                                let changePercent = Double(item["priceChangePercent"] as? String ?? "0") ?? 0.0
                                let change24h = Double(item["priceChange"] as? String ?? "0") ?? 0.0
                                
                                self.cryptocurrencies[symbol]?.price = price
                                self.cryptocurrencies[symbol]?.change24h = change24h
                                self.cryptocurrencies[symbol]?.changePercent24h = changePercent
                                self.cryptocurrencies[symbol]?.lastUpdate = Date()
                            }
                        }
                        self.updateUI()
                    }
                }
            } catch {
                print("Error parsing initial prices JSON: \(error.localizedDescription)")
            }
        }
        
        task.resume()

        // Fetch Futures tickers for Futures-only symbols
        fetchFuturesInitialPrices()
    }

    private func fetchFuturesInitialPrices() {
        for symbol in futuresSymbols {
            guard let url = URL(string: "https://fapi.binance.com/fapi/v1/ticker/24hr?symbol=\(symbol)") else { continue }
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self, let data = data, error == nil else {
                    print("Error fetching futures price for \(symbol): \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let priceString = json["lastPrice"] as? String,
                           let price = Double(priceString) {
                            let changePercent = Double(json["priceChangePercent"] as? String ?? "0") ?? 0.0
                            let change24h = Double(json["priceChange"] as? String ?? "0") ?? 0.0
                            DispatchQueue.main.async {
                                self.cryptocurrencies[symbol]?.price = price
                                self.cryptocurrencies[symbol]?.change24h = change24h
                                self.cryptocurrencies[symbol]?.changePercent24h = changePercent
                                self.cryptocurrencies[symbol]?.lastUpdate = Date()
                                self.updateUI()
                            }
                        }
                    }
                } catch {
                    print("Error parsing futures price JSON for \(symbol): \(error.localizedDescription)")
                }
            }
            task.resume()
        }
    }
    
    private func connectToWebSocket() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)

        // Create streams for Spot-only symbols
        let spotSymbols = supportedCryptocurrencies.keys.filter { !futuresSymbols.contains($0) }
        guard !spotSymbols.isEmpty else {
            print("No spot symbols to subscribe")
            return
        }
        let streams = spotSymbols.map { "\($0.lowercased())@ticker" }.joined(separator: "/")

        guard let url = URL(string: "wss://stream.binance.com:9443/stream?streams=\(streams)") else {
            print("Invalid WebSocket URL (Spot)")
            return
        }

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)

        webSocketTask?.resume()
        receiveMessage()

        print("WebSocket connecting to Binance Spot for: \(spotSymbols.joined(separator: ", "))")
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("WebSocket (Spot) receive error: \(error)")
                self?.scheduleReconnect()
                
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received WebSocket message (Spot): \(text)")
                    self?.processBinanceMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        print("Received WebSocket data (Spot): \(text)")
                        self?.processBinanceMessage(text)
                    }
                @unknown default:
                    break
                }
                
                self?.receiveMessage()
            }
        }
    }

    private func connectToFuturesWebSocket() {
        webSocketTaskFutures?.cancel(with: .goingAway, reason: nil)

        let futSymbols = futuresSymbols.filter { supportedCryptocurrencies[$0] != nil }
        guard !futSymbols.isEmpty else {
            print("No futures symbols to subscribe")
            return
        }
        let streams = futSymbols.map { "\($0.lowercased())@ticker" }.joined(separator: "/")

        guard let url = URL(string: "wss://fstream.binance.com/stream?streams=\(streams)") else {
            print("Invalid WebSocket URL (Futures)")
            return
        }

        let session = URLSession(configuration: .default)
        webSocketTaskFutures = session.webSocketTask(with: url)
        webSocketTaskFutures?.resume()
        receiveFuturesMessage()

        print("WebSocket connecting to Binance Futures for: \(futSymbols.joined(separator: ", "))")
    }

    private func receiveFuturesMessage() {
        webSocketTaskFutures?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("WebSocket (Futures) receive error: \(error)")
                self?.scheduleReconnectFutures()
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received WebSocket message (Futures): \(text)")
                    self?.processBinanceMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        print("Received WebSocket data (Futures): \(text)")
                        self?.processBinanceMessage(text)
                    }
                @unknown default:
                    break
                }
                self?.receiveFuturesMessage()
            }
        }
    }
    
    private func processBinanceMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else { 
            print("Failed to convert message to data")
            return 
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Handle multi-stream format
                if let stream = json["stream"] as? String,
                   let tickerData = json["data"] as? [String: Any] {
                    
                    // Extract symbol from stream (e.g., "btcusdt@ticker" -> "BTCUSDT")
                    let symbol = String(stream.prefix(while: { $0 != "@" })).uppercased()
                    
                    if let priceString = tickerData["c"] as? String,
                       let price = Double(priceString),
                       supportedCryptocurrencies[symbol] != nil {
                        
                        // Extract 24hr change data
                        let changePercent24h = Double(tickerData["P"] as? String ?? "0") ?? 0.0
                        let change24h = Double(tickerData["p"] as? String ?? "0") ?? 0.0
                        
                        print("Extracted \(symbol) - Price: \(price), Change: \(changePercent24h)%")
                        
                        DispatchQueue.main.async {
                            self.cryptocurrencies[symbol]?.price = price
                            self.cryptocurrencies[symbol]?.change24h = change24h
                            self.cryptocurrencies[symbol]?.changePercent24h = changePercent24h
                            self.cryptocurrencies[symbol]?.lastUpdate = Date()
                            self.updateUI()
                            print("UI updated with \(symbol) - Price: \(price), Change: \(changePercent24h)%")
                        }
                    }
                }
                // Handle single ticker format (fallback)
                else if let priceString = json["c"] as? String,
                        let price = Double(priceString) {
                    
                    let changePercent = Double(json["P"] as? String ?? "0") ?? 0.0
                    let change24h = Double(json["p"] as? String ?? "0") ?? 0.0
                    
                    print("Extracted price (fallback): \(price), Change: \(changePercent)%")
                    
                    DispatchQueue.main.async {
                        self.cryptocurrencies[self.selectedCrypto]?.price = price
                        self.cryptocurrencies[self.selectedCrypto]?.change24h = change24h
                        self.cryptocurrencies[self.selectedCrypto]?.changePercent24h = changePercent
                        self.cryptocurrencies[self.selectedCrypto]?.lastUpdate = Date()
                        self.updateUI()
                    }
                }
            }
        } catch {
            print("Error parsing Binance JSON: \(error)")
        }
    }
    
    private func scheduleReconnect() {
        DispatchQueue.main.async {
            self.reconnectTimer?.invalidate()
            self.reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                print("Attempting to reconnect WebSocket...")
                self.connectToWebSocket()
            }
        }
    }

    private func scheduleReconnectFutures() {
        DispatchQueue.main.async {
            self.reconnectTimerFutures?.invalidate()
            self.reconnectTimerFutures = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                print("Attempting to reconnect Futures WebSocket...")
                self.connectToFuturesWebSocket()
            }
        }
    }
    
    private func updateUI() {
        updateStatusBarForSelectedCrypto()
        updateMenuPrices()
    }
    
    private func updateStatusBarForSelectedCrypto() {
        if selectedCryptos.isEmpty { selectedCryptos = ["BTCUSDT"] }
        
        let entries: [String] = selectedCryptos.prefix(3).compactMap { symbol in
            guard let c = cryptocurrencies[symbol] else { return nil }
            let priceString = formatPrice(c.price)
            let changeString = formatPercentChange(c.changePercent24h)
            return "\(c.emoji) $\(priceString) \(changeString)"
        }

        if let button = statusItem?.button {
            button.title = entries.joined(separator: " | ")
            print("Status bar updated: \(button.title)")
        }

        // Update summary line in menu
        if let menu = statusItem?.menu,
           let priceItem = menu.item(withTag: 100) {
            let summary = selectedCryptos.isEmpty ? "Selected: None" : "Selected: \(selectedCryptos.joined(separator: ", "))"
            priceItem.title = summary
        }
    }
    
    private func updateMenuPrices() {
        guard let menu = statusItem?.menu,
              let allCryptosItem = menu.item(withTitle: "All Cryptocurrencies"),
              let submenu = allCryptosItem.submenu else { return }
        
        for item in submenu.items {
            if let symbol = item.representedObject as? String,
               let crypto = cryptocurrencies[symbol] {
                let priceString = formatPrice(crypto.price)
                let changeString = formatPercentChange(crypto.changePercent24h)
                let isSelected = selectedCryptos.contains(symbol) ? " ✓" : ""
                item.title = "\(crypto.emoji) \(crypto.name): $\(priceString) \(changeString)\(isSelected)"
            }
        }
    }

    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true

        let fractionDigits: Int
        let absolutePrice = abs(price)

        switch absolutePrice {
        case ..<10:
            fractionDigits = 4
        case ..<100:
            fractionDigits = 3
        case ..<10_000:
            fractionDigits = 2
        default:
            fractionDigits = 1
        }

        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits

        if let formatted = formatter.string(from: NSNumber(value: price)) {
            return formatted
        }

        return String(format: "%.*f", fractionDigits, price)
    }
    
    private func formatPercentChange(_ change: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.positivePrefix = "+"
        
        let changeString = formatter.string(from: NSNumber(value: change)) ?? "0.00"
        
        if change > 0 {
            return "(\(changeString)%)"  // Positive changes
        } else if change < 0 {
            return "(\(changeString)%)"  // Negative changes
        } else {
            return "(0.00%)"  // No change
        }
    }
}
