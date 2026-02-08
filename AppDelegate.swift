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
    var cryptocurrencies: [String: CryptoCurrency] = [:]
    var selectedCryptos: [String] = []
    var selectedCrypto: String { selectedCryptos.first ?? "BTCUSDT" }
    var reconnectTimer: Timer?
    var topListRefreshTimer: Timer?
    var currentTopSymbols: [String] = []
    var iconCache: [String: NSImage] = [:]

    // Pinned symbols always shown regardless of volume ranking
    private let pinnedSymbols: [String] = ["PAXGUSDT", "HYPEUSDT"]

    // Stablecoins and wrapped tokens to exclude from volume ranking
    private let excludedSymbols: Set<String> = [
        "USDCUSDT", "FDUSDUSDT", "BUSDUSDT", "TUSDUSDT", "DAIUSDT",
        "USDPUSDT", "EURUSDT", "GBPUSDT", "BTTCUSDT"
    ]

    // CoinMarketCap ID mapping for coin logo icons
    private let knownCMCIds: [String: Int] = [
        "BTC": 1, "ETH": 1027, "BNB": 1839, "XRP": 52, "SOL": 5426,
        "DOGE": 74, "ADA": 2010, "TRX": 1958, "LINK": 1975, "AVAX": 5805,
        "DOT": 6636, "SUI": 20947, "HYPE": 32196, "PAXG": 4705,
        "LTC": 2, "NEAR": 6535, "APT": 21794, "ARB": 11841, "OP": 11840,
        "UNI": 7083, "ATOM": 3794, "AAVE": 7278, "MATIC": 3890, "POL": 3890,
        "XLM": 512, "HBAR": 4642, "FIL": 2280, "INJ": 7226, "MKR": 1518,
        "CRV": 6538, "PEPE": 24478, "BCH": 1831, "ETC": 1321,
        "SHIB": 5994, "TON": 11419, "XMR": 328, "ALGO": 4030, "VET": 3077,
        "ICP": 8916, "FTM": 3513, "THETA": 2416, "EOS": 1765, "IOTA": 1720,
        "WIF": 28752, "RENDER": 5690, "FET": 3773, "TAO": 22974,
        "BONK": 23095, "FLOKI": 10804, "WLD": 13502, "SEI": 23149,
        "TRUMP": 35336, "VIRTUAL": 28658, "USUAL": 34403, "PENGU": 35135,
        "KAITO": 36498, "BERA": 35899, "IP": 36785, "LAYER": 33758
    ]

    // Known full names for popular coins
    private let knownNames: [String: String] = [
        "BTC": "Bitcoin", "ETH": "Ethereum", "BNB": "BNB", "XRP": "XRP",
        "SOL": "Solana", "DOGE": "Dogecoin", "ADA": "Cardano", "TRX": "TRON",
        "LINK": "Chainlink", "AVAX": "Avalanche", "DOT": "Polkadot",
        "SUI": "Sui", "HYPE": "Hyperliquid", "PAXG": "Pax Gold",
        "LTC": "Litecoin", "NEAR": "NEAR Protocol", "APT": "Aptos",
        "ARB": "Arbitrum", "OP": "Optimism", "UNI": "Uniswap",
        "ATOM": "Cosmos", "AAVE": "Aave", "MATIC": "Polygon", "POL": "Polygon",
        "XLM": "Stellar", "HBAR": "Hedera", "FIL": "Filecoin",
        "INJ": "Injective", "MKR": "Maker", "CRV": "Curve",
        "PEPE": "Pepe", "BCH": "Bitcoin Cash", "ETC": "Ethereum Classic",
        "SHIB": "Shiba Inu", "TON": "Toncoin", "XMR": "Monero",
        "ALGO": "Algorand", "VET": "VeChain", "ICP": "Internet Computer",
        "FTM": "Fantom", "THETA": "Theta", "EOS": "EOS", "IOTA": "IOTA",
        "WIF": "dogwifhat", "RENDER": "Render", "FET": "Fetch.ai",
        "TAO": "Bittensor", "BONK": "Bonk", "FLOKI": "Floki",
        "WLD": "Worldcoin", "SEI": "Sei", "TRUMP": "TRUMP",
        "VIRTUAL": "Virtuals Protocol", "USUAL": "Usual",
        "PENGU": "Pudgy Penguins", "KAITO": "Kaito",
        "BERA": "Berachain", "IP": "Story Protocol", "LAYER": "UniLayer"
    ]

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("App launched successfully!")
        setupStatusBar()
        print("Status bar setup complete")
        fetchTopCryptocurrencies { [weak self] in
            self?.downloadAllIcons()
            self?.connectToWebSocket()
        }
        scheduleTopListRefresh()
        print("Fetching top cryptocurrencies by volume...")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        reconnectTimer?.invalidate()
        topListRefreshTimer?.invalidate()
    }

    // MARK: - Status Bar Setup

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "Loading top coins..."
            button.target = self
            button.action = #selector(statusBarButtonClicked)
        }

        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()

        // Summary line
        let summaryItem = NSMenuItem(title: "Top 10 by 24h Volume", action: nil, keyEquivalent: "")
        summaryItem.tag = 100
        menu.addItem(summaryItem)

        menu.addItem(NSMenuItem.separator())

        // All cryptocurrencies submenu
        let allCryptosItem = NSMenuItem(title: "All Cryptocurrencies", action: nil, keyEquivalent: "")
        let allCryptosMenu = NSMenu()

        for symbol in currentTopSymbols {
            if let crypto = cryptocurrencies[symbol] {
                let cryptoItem = NSMenuItem(
                    title: "\(crypto.name): Loading...",
                    action: #selector(toggleCryptocurrency(_:)),
                    keyEquivalent: ""
                )
                cryptoItem.target = self
                cryptoItem.tag = symbol.hashValue
                cryptoItem.representedObject = symbol

                // Set icon if available
                if let icon = iconCache[symbol] {
                    let menuIcon = resizeImage(icon, to: NSSize(width: 18, height: 18))
                    cryptoItem.image = menuIcon
                }

                allCryptosMenu.addItem(cryptoItem)
            }
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

    // MARK: - Top Cryptocurrencies Fetch

    private func fetchTopCryptocurrencies(completion: @escaping () -> Void) {
        guard let url = URL(string: "https://api.binance.com/api/v3/ticker/24hr") else {
            completion()
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                print("Error fetching ticker data: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async { completion() }
                return
            }

            do {
                guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                    DispatchQueue.main.async { completion() }
                    return
                }

                // Filter USDT pairs, exclude stablecoins, sort by quoteVolume
                let usdtPairs = jsonArray.filter { item in
                    guard let symbol = item["symbol"] as? String else { return false }
                    return symbol.hasSuffix("USDT")
                        && !self.excludedSymbols.contains(symbol)
                }

                let sortedByVolume = usdtPairs.sorted { a, b in
                    let volA = Double(a["quoteVolume"] as? String ?? "0") ?? 0
                    let volB = Double(b["quoteVolume"] as? String ?? "0") ?? 0
                    return volA > volB
                }

                let top10 = Array(sortedByVolume.prefix(10))
                var newSymbols = top10.compactMap { $0["symbol"] as? String }

                // Add pinned symbols if not already in top 10
                for pinned in self.pinnedSymbols {
                    if !newSymbols.contains(pinned) {
                        newSymbols.append(pinned)
                    }
                }

                // Build lookup for all ticker data
                var tickerLookup: [String: [String: Any]] = [:]
                for item in jsonArray {
                    if let symbol = item["symbol"] as? String {
                        tickerLookup[symbol] = item
                    }
                }

                DispatchQueue.main.async {
                    let listChanged = newSymbols != self.currentTopSymbols
                    self.currentTopSymbols = newSymbols

                    // Build CryptoCurrency instances and populate prices
                    var newCryptos: [String: CryptoCurrency] = [:]
                    for symbol in newSymbols {
                        let baseSymbol = self.extractBaseSymbol(from: symbol)
                        let name = self.knownNames[baseSymbol] ?? baseSymbol
                        let emoji = "🪙"

                        var crypto = CryptoCurrency(symbol: symbol, name: name, emoji: emoji)

                        if let ticker = tickerLookup[symbol] {
                            crypto.price = Double(ticker["lastPrice"] as? String ?? "0") ?? 0
                            crypto.change24h = Double(ticker["priceChange"] as? String ?? "0") ?? 0
                            crypto.changePercent24h = Double(ticker["priceChangePercent"] as? String ?? "0") ?? 0
                            crypto.lastUpdate = Date()
                        }

                        newCryptos[symbol] = crypto
                    }

                    self.cryptocurrencies = newCryptos
                    self.selectedCryptos = newSymbols

                    if listChanged {
                        self.setupMenu()
                    }

                    self.updateUI()
                    completion()
                }
            } catch {
                print("Error parsing ticker JSON: \(error.localizedDescription)")
                DispatchQueue.main.async { completion() }
            }
        }

        task.resume()
    }

    private func extractBaseSymbol(from tradingPair: String) -> String {
        if tradingPair.hasSuffix("USDT") {
            return String(tradingPair.dropLast(4))
        }
        return tradingPair
    }

    private func scheduleTopListRefresh() {
        topListRefreshTimer?.invalidate()
        topListRefreshTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            print("Refreshing top 10 list...")
            self?.fetchTopCryptocurrencies {
                self?.downloadAllIcons()
                self?.connectToWebSocket()
            }
        }
    }

    // MARK: - Icon Download

    private func downloadAllIcons() {
        for symbol in currentTopSymbols {
            if iconCache[symbol] != nil { continue }
            downloadCoinIcon(symbol: symbol)
        }
    }

    private func downloadCoinIcon(symbol: String) {
        let baseSymbol = extractBaseSymbol(from: symbol)
        guard let cmcId = knownCMCIds[baseSymbol] else {
            print("No CMC ID for \(baseSymbol), using emoji fallback")
            return
        }

        let urlString = "https://s2.coinmarketcap.com/static/img/coins/64x64/\(cmcId).png"
        guard let url = URL(string: urlString) else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil,
                  let image = NSImage(data: data) else {
                print("Failed to download icon for \(baseSymbol)")
                return
            }

            DispatchQueue.main.async {
                self.iconCache[symbol] = image
                self.updateMenuIcons()
                self.updateStatusBarForSelectedCrypto()
            }
        }
        task.resume()
    }

    private func resizeImage(_ image: NSImage, to size: NSSize) -> NSImage {
        let resized = NSImage(size: size)
        resized.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        resized.unlockFocus()
        return resized
    }

    private func updateMenuIcons() {
        guard let menu = statusItem?.menu,
              let allCryptosItem = menu.item(withTitle: "All Cryptocurrencies"),
              let submenu = allCryptosItem.submenu else { return }

        for item in submenu.items {
            if let symbol = item.representedObject as? String,
               let icon = iconCache[symbol] {
                item.image = resizeImage(icon, to: NSSize(width: 18, height: 18))
            }
        }
    }

    // MARK: - User Actions

    @objc func toggleCryptocurrency(_ sender: NSMenuItem) {
        guard let symbol = sender.representedObject as? String else { return }
        if let idx = selectedCryptos.firstIndex(of: symbol) {
            selectedCryptos.remove(at: idx)
        } else {
            if selectedCryptos.count >= 10 {
                let alert = NSAlert()
                alert.messageText = "Selection limit reached"
                alert.informativeText = "You can select up to 10 currencies."
                alert.alertStyle = .warning
                alert.runModal()
            } else {
                selectedCryptos.append(symbol)
            }
        }
        updateStatusBarForSelectedCrypto()
        updateMenuPrices()
    }

    @objc func statusBarButtonClicked() {
        // Menu will show automatically
    }

    @objc func reconnectWebSocket() {
        print("Manual reconnect requested")
        fetchTopCryptocurrencies { [weak self] in
            self?.downloadAllIcons()
            self?.connectToWebSocket()
        }
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Crypto Price Monitor"
        alert.informativeText = "Displays top 10 cryptocurrencies by 24h trading volume.\n\nPinned: PAXG, HYPE\n\nReal-time data from Binance WebSocket API\nCoin icons from CoinMarketCap"
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - WebSocket

    private func connectToWebSocket() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)

        guard !currentTopSymbols.isEmpty else {
            print("No symbols to subscribe")
            return
        }

        let streams = currentTopSymbols.map { "\($0.lowercased())@ticker" }.joined(separator: "/")

        guard let url = URL(string: "wss://stream.binance.com:9443/stream?streams=\(streams)") else {
            print("Invalid WebSocket URL")
            return
        }

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessage()

        print("WebSocket connecting for: \(currentTopSymbols.joined(separator: ", "))")
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self?.scheduleReconnect()

            case .success(let message):
                switch message {
                case .string(let text):
                    self?.processBinanceMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.processBinanceMessage(text)
                    }
                @unknown default:
                    break
                }

                self?.receiveMessage()
            }
        }
    }

    private func processBinanceMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Handle multi-stream format
                if let stream = json["stream"] as? String,
                   let tickerData = json["data"] as? [String: Any] {

                    let symbol = String(stream.prefix(while: { $0 != "@" })).uppercased()

                    if let priceString = tickerData["c"] as? String,
                       let price = Double(priceString),
                       cryptocurrencies[symbol] != nil {

                        let changePercent24h = Double(tickerData["P"] as? String ?? "0") ?? 0.0
                        let change24h = Double(tickerData["p"] as? String ?? "0") ?? 0.0

                        DispatchQueue.main.async {
                            self.cryptocurrencies[symbol]?.price = price
                            self.cryptocurrencies[symbol]?.change24h = change24h
                            self.cryptocurrencies[symbol]?.changePercent24h = changePercent24h
                            self.cryptocurrencies[symbol]?.lastUpdate = Date()
                            self.updateUI()
                        }
                    }
                }
                // Handle single ticker format (fallback)
                else if let priceString = json["c"] as? String,
                        let price = Double(priceString) {

                    let changePercent = Double(json["P"] as? String ?? "0") ?? 0.0
                    let change24h = Double(json["p"] as? String ?? "0") ?? 0.0

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

    // MARK: - UI Updates

    private func updateUI() {
        updateStatusBarForSelectedCrypto()
        updateMenuPrices()
    }

    private func updateStatusBarForSelectedCrypto() {
        if selectedCryptos.isEmpty { return }

        let attributedString = NSMutableAttributedString()
        let font = NSFont.systemFont(ofSize: 12)

        for (index, symbol) in selectedCryptos.prefix(10).enumerated() {
            guard let c = cryptocurrencies[symbol] else { continue }

            if index > 0 {
                attributedString.append(NSAttributedString(string: " | ", attributes: [.font: font]))
            }

            // Add icon or emoji
            if let icon = iconCache[symbol] {
                let attachment = NSTextAttachment()
                let iconSize: CGFloat = 16
                let resized = resizeImage(icon, to: NSSize(width: iconSize, height: iconSize))
                attachment.image = resized
                // Vertically center the icon with the text
                attachment.bounds = CGRect(x: 0, y: (font.capHeight - iconSize) / 2.0, width: iconSize, height: iconSize)
                attributedString.append(NSAttributedString(attachment: attachment))
                attributedString.append(NSAttributedString(string: " ", attributes: [.font: font]))
            }

            let priceString = formatPrice(c.price)
            let changeString = formatPercentChange(c.changePercent24h)
            attributedString.append(NSAttributedString(string: "$\(priceString) \(changeString)", attributes: [.font: font]))
        }

        if let button = statusItem?.button {
            button.attributedTitle = attributedString
        }

        // Update summary line in menu
        if let menu = statusItem?.menu,
           let summaryItem = menu.item(withTag: 100) {
            let pinnedCount = pinnedSymbols.filter { currentTopSymbols.contains($0) && !Array(currentTopSymbols.prefix(10)).contains($0) }.count
            summaryItem.title = "Top 10 by 24h Volume" + (pinnedCount > 0 ? " + \(pinnedCount) pinned" : "")
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
                let isPinned = pinnedSymbols.contains(symbol) ? " 📌" : ""
                item.title = "\(crypto.name): $\(priceString) \(changeString)\(isPinned)\(isSelected)"

                // Update icon
                if let icon = iconCache[symbol] {
                    item.image = resizeImage(icon, to: NSSize(width: 18, height: 18))
                }
            }
        }
    }

    // MARK: - Price Formatting

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
            return "(\(changeString)%)"
        } else if change < 0 {
            return "(\(changeString)%)"
        } else {
            return "(0.00%)"
        }
    }
}
