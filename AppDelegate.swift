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
    var selectedCryptos: [String] = []
    var selectedCrypto: String { selectedCryptos.first ?? "BTCUSDT" }
    var reconnectTimer: Timer?
    var reconnectTimerFutures: Timer?
    var iconCache: [String: NSImage] = [:]

    // Symbols only available on Binance Futures (not on Spot)
    private let futuresOnlySymbols: Set<String> = ["HYPEUSDT"]

    // Fixed top 30 cryptocurrency list
    private let fixedTopSymbols: [String] = [
        "BTCUSDT", "ETHUSDT", "BNBUSDT", "XRPUSDT", "SOLUSDT",
        "DOGEUSDT", "ADAUSDT", "TRXUSDT", "LINKUSDT", "AVAXUSDT",
        "DOTUSDT", "SUIUSDT", "HYPEUSDT", "PAXGUSDT", "LTCUSDT",
        "NEARUSDT", "APTUSDT", "ARBUSDT", "OPUSDT", "UNIUSDT",
        "ATOMUSDT", "AAVEUSDT", "XLMUSDT", "HBARUSDT", "FILUSDT",
        "INJUSDT", "PEPEUSDT", "BCHUSDT", "ETCUSDT", "ASTERUSDT"
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
        "KAITO": 36498, "BERA": 35899, "IP": 36785, "LAYER": 33758,
        "ASTER": 36341, "ZEC": 1684, "USD1": 36148
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
        "BERA": "Berachain", "IP": "Story Protocol", "LAYER": "UniLayer",
        "ASTER": "Aster", "ZEC": "Zcash", "USD1": "USD1"
    ]

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("App launched successfully!")
        initializeCryptocurrencies()
        setupStatusBar()
        print("Status bar setup complete")
        fetchInitialPrices {
            self.downloadAllIcons()
            self.connectToWebSocket()
            self.connectToFuturesWebSocket()
        }
        print("Loading fixed top 30 cryptocurrencies...")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTaskFutures?.cancel(with: .goingAway, reason: nil)
        reconnectTimer?.invalidate()
        reconnectTimerFutures?.invalidate()
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
        let summaryItem = NSMenuItem(title: "Top 30 Cryptocurrencies", action: nil, keyEquivalent: "")
        summaryItem.tag = 100
        menu.addItem(summaryItem)

        menu.addItem(NSMenuItem.separator())

        // All cryptocurrencies submenu
        let allCryptosItem = NSMenuItem(title: "All Cryptocurrencies", action: nil, keyEquivalent: "")
        let allCryptosMenu = NSMenu()

        for symbol in fixedTopSymbols {
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

    // MARK: - Initialize Fixed Cryptocurrencies

    private func initializeCryptocurrencies() {
        for symbol in fixedTopSymbols {
            let baseSymbol = extractBaseSymbol(from: symbol)
            let name = knownNames[baseSymbol] ?? baseSymbol
            cryptocurrencies[symbol] = CryptoCurrency(symbol: symbol, name: name, emoji: "🪙")
        }
        if selectedCryptos.isEmpty {
            selectedCryptos = ["BTCUSDT"]
        }
    }

    private func extractBaseSymbol(from tradingPair: String) -> String {
        if tradingPair.hasSuffix("USDT") {
            return String(tradingPair.dropLast(4))
        }
        return tradingPair
    }

    // MARK: - Fetch Initial Prices

    private func fetchInitialPrices(completion: @escaping () -> Void) {
        // Fetch spot prices
        let spotSymbols = fixedTopSymbols.filter { !futuresOnlySymbols.contains($0) }
        let symbolsParam = spotSymbols.map { "\"\($0)\"" }.joined(separator: ",")
        let urlString = "https://api.binance.com/api/v3/ticker/24hr?symbols=[\(symbolsParam)]"
        guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedString) else {
            completion()
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                print("Error fetching initial prices: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async { completion() }
                return
            }

            do {
                guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                    DispatchQueue.main.async { completion() }
                    return
                }

                DispatchQueue.main.async {
                    for item in jsonArray {
                        guard let symbol = item["symbol"] as? String,
                              self.cryptocurrencies[symbol] != nil else { continue }
                        self.cryptocurrencies[symbol]?.price = Double(item["lastPrice"] as? String ?? "0") ?? 0
                        self.cryptocurrencies[symbol]?.change24h = Double(item["priceChange"] as? String ?? "0") ?? 0
                        self.cryptocurrencies[symbol]?.changePercent24h = Double(item["priceChangePercent"] as? String ?? "0") ?? 0
                        self.cryptocurrencies[symbol]?.lastUpdate = Date()
                    }
                    self.updateUI()

                    // Fetch futures-only symbols separately
                    self.fetchFuturesInitialPrices {
                        completion()
                    }
                }
            } catch {
                print("Error parsing initial prices JSON: \(error.localizedDescription)")
                DispatchQueue.main.async { completion() }
            }
        }
        task.resume()
    }

    private func fetchFuturesInitialPrices(completion: @escaping () -> Void) {
        let futuresSymbols = fixedTopSymbols.filter { futuresOnlySymbols.contains($0) }
        guard !futuresSymbols.isEmpty else {
            completion()
            return
        }

        let group = DispatchGroup()
        for symbol in futuresSymbols {
            guard let url = URL(string: "https://fapi.binance.com/fapi/v1/ticker/24hr?symbol=\(symbol)") else { continue }
            group.enter()
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                defer { group.leave() }
                guard let self = self, let data = data, error == nil else {
                    print("Error fetching futures price for \(symbol): \(error?.localizedDescription ?? "Unknown")")
                    return
                }
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let priceString = json["lastPrice"] as? String,
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
                } catch {
                    print("Error parsing futures JSON for \(symbol): \(error)")
                }
            }
            task.resume()
        }
        group.notify(queue: .main) {
            completion()
        }
    }

    // MARK: - Icon Download

    private func downloadAllIcons() {
        for symbol in fixedTopSymbols {
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
        fetchInitialPrices { [weak self] in
            self?.downloadAllIcons()
            self?.connectToWebSocket()
            self?.connectToFuturesWebSocket()
        }
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Crypto Price Monitor"
        alert.informativeText = "Displays top 30 cryptocurrencies with real-time prices.\n\nCreated by github.com/Gamezxz\n\nReal-time data from Binance WebSocket API\nCoin icons from CoinMarketCap"
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - WebSocket (Spot)

    private func connectToWebSocket() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)

        // Only subscribe to spot symbols (exclude futures-only)
        let spotSymbols = fixedTopSymbols.filter { !futuresOnlySymbols.contains($0) }
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

        print("WebSocket (Spot) connecting for: \(spotSymbols.joined(separator: ", "))")
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

    // MARK: - WebSocket (Futures)

    private func connectToFuturesWebSocket() {
        webSocketTaskFutures?.cancel(with: .goingAway, reason: nil)

        let futSymbols = fixedTopSymbols.filter { futuresOnlySymbols.contains($0) }
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

        print("WebSocket (Futures) connecting for: \(futSymbols.joined(separator: ", "))")
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
                    self?.processBinanceMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
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
                print("Attempting to reconnect Spot WebSocket...")
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
            summaryItem.title = "Top 30 Cryptocurrencies"
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
                item.title = "\(crypto.name): $\(priceString) \(changeString)\(isSelected)"

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
