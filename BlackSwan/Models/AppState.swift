import Foundation
import SwiftUI
import Combine

enum ConnectionStatus: String {
    case disconnected = "Disconnected"
    case connecting = "Connecting..."
    case connected = "Connected"
    case scanning = "Scanning..."
    case error = "Error"
}

@MainActor
class AppState: ObservableObject {
    @Published var configs: [SlipnetConfig] = []
    @Published var selectedConfigID: UUID?
    @Published var terminalOutput: String = ""
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var scanConfig: ScanConfig = ScanConfig()
    @Published var slipnetPath: String = ""
    @Published var isUpdating: Bool = false
    @Published var updateStatus: String = ""
    @Published var socksProxyEnabled: Bool = false
    @Published var socksProxyInterface: String = UserDefaults.standard.string(forKey: "blackswan.proxyInterface") ?? "Wi-Fi"

    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?

    private let configsKey = "blackswan.configs"
    private let slipnetPathKey = "blackswan.slipnetPath"

    var selectedConfig: SlipnetConfig? {
        get {
            configs.first { $0.id == selectedConfigID }
        }
        set {
            if let newValue = newValue, let idx = configs.firstIndex(where: { $0.id == newValue.id }) {
                configs[idx] = newValue
            }
        }
    }

    init() {
        loadConfigs()
        detectSlipnetPath()
    }

    private func detectSlipnetPath() {
        let savedPath = UserDefaults.standard.string(forKey: slipnetPathKey) ?? ""
        if !savedPath.isEmpty && FileManager.default.isExecutableFile(atPath: savedPath) {
            slipnetPath = savedPath
            return
        }

        let bundle = Bundle.main.bundlePath
        let bundleDir = (bundle as NSString).deletingLastPathComponent
        let candidates = [
            bundleDir + "/slipnet",
            NSHomeDirectory() + "/Documents/WorkStuff/VPN-slipnet/slipnet",
            "/usr/local/bin/slipnet",
            "/opt/homebrew/bin/slipnet"
        ]

        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                slipnetPath = path
                UserDefaults.standard.set(path, forKey: slipnetPathKey)
                return
            }
        }
    }

    func setSlipnetPath(_ path: String) {
        slipnetPath = path
        UserDefaults.standard.set(path, forKey: slipnetPathKey)
    }

    func loadConfigs() {
        if let data = UserDefaults.standard.data(forKey: configsKey),
           let decoded = try? JSONDecoder().decode([SlipnetConfig].self, from: data) {
            configs = decoded
        }
    }

    func saveConfigs() {
        if let data = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(data, forKey: configsKey)
        }
    }

    func addConfig(_ config: SlipnetConfig) {
        configs.append(config)
        saveConfigs()
    }

    func deleteConfig(_ config: SlipnetConfig) {
        configs.removeAll { $0.id == config.id }
        if selectedConfigID == config.id {
            selectedConfigID = configs.first?.id
        }
        saveConfigs()
    }

    func updateConfig(_ config: SlipnetConfig) {
        if let idx = configs.firstIndex(where: { $0.id == config.id }) {
            configs[idx] = config
            saveConfigs()
        }
    }

    func duplicateConfig(_ config: SlipnetConfig) {
        var copy = config
        copy.id = UUID()
        copy.name = config.name + " (Copy)"
        copy.createdAt = Date()
        configs.append(copy)
        saveConfigs()
    }

    func appendOutput(_ text: String) {
        terminalOutput += text
        // Keep buffer reasonable
        if terminalOutput.count > 500_000 {
            let start = terminalOutput.index(terminalOutput.endIndex, offsetBy: -400_000)
            terminalOutput = String(terminalOutput[start...])
        }
    }

    func clearOutput() {
        terminalOutput = ""
    }

    func connect(config: SlipnetConfig) {
        guard !slipnetPath.isEmpty else {
            appendOutput("[BlackSwan] Error: slipnet binary not found. Set the path in Settings.\n")
            connectionStatus = .error
            return
        }
        guard !config.uri.isEmpty else {
            appendOutput("[BlackSwan] Error: No slipnet URI configured for this profile.\n")
            connectionStatus = .error
            return
        }

        stop()
        clearOutput()
        connectionStatus = .connecting

        let args = config.buildArguments()
        appendOutput("[BlackSwan] Connecting: \(slipnetPath) \(args.joined(separator: " "))\n")
        appendOutput("─────────────────────────────────────────────────\n")

        runProcess(arguments: args)
    }

    func connectWithCustomArgs(_ args: [String]) {
        guard !slipnetPath.isEmpty else {
            appendOutput("[BlackSwan] Error: slipnet binary not found. Set the path in Settings.\n")
            connectionStatus = .error
            return
        }

        stop()
        clearOutput()
        connectionStatus = .connecting

        appendOutput("[BlackSwan] Running: \(slipnetPath) \(args.joined(separator: " "))\n")
        appendOutput("─────────────────────────────────────────────────\n")

        runProcess(arguments: args)
    }

    func runScan() {
        guard !slipnetPath.isEmpty else {
            appendOutput("[BlackSwan] Error: slipnet binary not found. Set the path in Settings.\n")
            connectionStatus = .error
            return
        }

        stop()
        clearOutput()
        connectionStatus = .scanning

        let args = scanConfig.buildArguments()
        appendOutput("[BlackSwan] Scanning: \(slipnetPath) \(args.joined(separator: " "))\n")
        appendOutput("─────────────────────────────────────────────────\n")

        runProcess(arguments: args)
    }

    private func runProcess(arguments: [String]) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: slipnetPath)
        proc.arguments = arguments

        // Set working directory to slipnet's directory
        proc.currentDirectoryURL = URL(fileURLWithPath: (slipnetPath as NSString).deletingLastPathComponent)

        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe

        outputPipe = outPipe
        errorPipe = errPipe

        outPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                self?.appendOutput(text)
                if self?.connectionStatus == .connecting {
                    // Detect when connection is established
                    let lower = text.lowercased()
                    if lower.contains("listening") || lower.contains("connected") || lower.contains("socks5") || lower.contains("proxy") {
                        self?.connectionStatus = .connected
                    }
                }
            }
        }

        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                self?.appendOutput(text)
            }
        }

        proc.terminationHandler = { [weak self] proc in
            Task { @MainActor [weak self] in
                self?.appendOutput("\n─────────────────────────────────────────────────\n")
                self?.appendOutput("[BlackSwan] Process exited with code \(proc.terminationStatus)\n")
                if self?.connectionStatus != .error {
                    self?.connectionStatus = .disconnected
                }
                self?.process = nil
            }
        }

        do {
            try proc.run()
            process = proc
        } catch {
            appendOutput("[BlackSwan] Failed to start: \(error.localizedDescription)\n")
            connectionStatus = .error
        }
    }

    func stop() {
        // Auto-disable SOCKS proxy when disconnecting
        if socksProxyEnabled {
            disableSOCKSProxy()
        }

        if let proc = process, proc.isRunning {
            proc.terminate()
            appendOutput("\n[BlackSwan] Stopping...\n")
            // Give it a moment, then force kill if needed
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                if proc.isRunning {
                    proc.interrupt()
                }
            }
        }
        process = nil
        connectionStatus = .disconnected
    }

    var isRunning: Bool {
        process?.isRunning ?? false
    }

    func pasteAndConnect() {
        guard let clipboard = NSPasteboard.general.string(forType: .string) else {
            appendOutput("[BlackSwan] Clipboard is empty or doesn't contain text.\n")
            return
        }

        let trimmed = clipboard.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("slipnet://") || trimmed.hasPrefix("slipnet-enc://") {
            var config = SlipnetConfig()
            config.uri = trimmed
            config.name = "Clipboard (\(Date().formatted(date: .abbreviated, time: .shortened)))"
            connect(config: config)
        } else {
            appendOutput("[BlackSwan] Clipboard doesn't contain a valid slipnet:// URI.\n")
            appendOutput("[BlackSwan] Content: \(String(trimmed.prefix(100)))...\n")
        }
    }

    // MARK: - System SOCKS Proxy

    func enableSOCKSProxy() {
        guard connectionStatus == .connected else {
            appendOutput("[BlackSwan] Cannot enable SOCKS proxy: not connected.\n")
            return
        }

        let config = selectedConfig
        let host = config?.localHost.isEmpty == false ? config!.localHost : "127.0.0.1"
        let port = config?.localPort.isEmpty == false ? config!.localPort : "1080"
        let iface = socksProxyInterface

        UserDefaults.standard.set(iface, forKey: "blackswan.proxyInterface")

        Task.detached {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
            proc.arguments = ["-setsocksfirewallproxy", iface, host, port]
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = pipe
            do {
                try proc.run()
                proc.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                await MainActor.run {
                    if proc.terminationStatus == 0 {
                        self.socksProxyEnabled = true
                        self.appendOutput("[BlackSwan] SOCKS proxy enabled on \(iface) → \(host):\(port)\n")
                    } else {
                        self.appendOutput("[BlackSwan] Failed to enable SOCKS proxy: \(output)\n")
                    }
                }
            } catch {
                await MainActor.run {
                    self.appendOutput("[BlackSwan] Failed to run networksetup: \(error.localizedDescription)\n")
                }
            }
        }
    }

    func disableSOCKSProxy() {
        let iface = socksProxyInterface
        Task.detached {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
            proc.arguments = ["-setsocksfirewallproxystate", iface, "off"]
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = pipe
            do {
                try proc.run()
                proc.waitUntilExit()
                await MainActor.run {
                    self.socksProxyEnabled = false
                    self.appendOutput("[BlackSwan] SOCKS proxy disabled on \(iface)\n")
                }
            } catch {
                await MainActor.run {
                    self.appendOutput("[BlackSwan] Failed to disable SOCKS proxy: \(error.localizedDescription)\n")
                }
            }
        }
    }

    func toggleSOCKSProxy() {
        if socksProxyEnabled {
            disableSOCKSProxy()
        } else {
            enableSOCKSProxy()
        }
    }

    func updateSlipnet() {
        guard !isUpdating else { return }
        isUpdating = true
        updateStatus = "Checking for updates..."

        Task {
            do {
                let result = try await downloadLatestSlipnet()
                await MainActor.run {
                    self.updateStatus = result
                    self.isUpdating = false
                }
            } catch {
                await MainActor.run {
                    self.updateStatus = "Update failed: \(error.localizedDescription)"
                    self.isUpdating = false
                }
            }
        }
    }

    private func downloadLatestSlipnet() async throws -> String {
        // Get latest release info from GitHub API
        let apiURL = URL(string: "https://api.github.com/repos/anonvector/SlipNet/releases/latest")!
        let (data, _) = try await URLSession.shared.data(from: apiURL)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let assets = json["assets"] as? [[String: Any]],
              let tagName = json["tag_name"] as? String else {
            return "Could not parse release info"
        }

        // Look for macOS arm64 or darwin asset
        let assetNames = ["slipnet-darwin-arm64", "slipnet-macos-arm64", "slipnet-darwin", "slipnet-macos", "slipnet"]
        var downloadURL: String?
        var assetName: String?

        for asset in assets {
            guard let name = asset["name"] as? String,
                  let url = asset["browser_download_url"] as? String else { continue }
            let lowerName = name.lowercased()
            if lowerName.contains("darwin") || lowerName.contains("macos") {
                if lowerName.contains("arm64") || lowerName.contains("aarch64") {
                    downloadURL = url
                    assetName = name
                    break
                }
                if downloadURL == nil {
                    downloadURL = url
                    assetName = name
                }
            }
        }

        // Fallback: try matching by name
        if downloadURL == nil {
            for target in assetNames {
                for asset in assets {
                    if let name = asset["name"] as? String, let url = asset["browser_download_url"] as? String {
                        if name.lowercased() == target.lowercased() {
                            downloadURL = url
                            assetName = name
                            break
                        }
                    }
                }
                if downloadURL != nil { break }
            }
        }

        guard let url = downloadURL, let name = assetName else {
            return "No compatible macOS binary found in release \(tagName). Assets: \(assets.compactMap { $0["name"] as? String }.joined(separator: ", "))"
        }

        await MainActor.run {
            self.updateStatus = "Downloading \(name) (\(tagName))..."
        }

        // Download the binary
        let (fileData, _) = try await URLSession.shared.data(from: URL(string: url)!)

        // Determine destination path
        let destPath = slipnetPath.isEmpty
            ? (Bundle.main.bundlePath as NSString).deletingLastPathComponent + "/slipnet"
            : slipnetPath

        // Backup existing
        let backupPath = destPath + ".backup"
        if FileManager.default.fileExists(atPath: destPath) {
            try? FileManager.default.removeItem(atPath: backupPath)
            try FileManager.default.copyItem(atPath: destPath, toPath: backupPath)
        }

        // Write new binary
        try fileData.write(to: URL(fileURLWithPath: destPath))

        // Make executable
        let attrs: [FileAttributeKey: Any] = [.posixPermissions: 0o755]
        try FileManager.default.setAttributes(attrs, ofItemAtPath: destPath)

        slipnetPath = destPath
        UserDefaults.standard.set(destPath, forKey: slipnetPathKey)

        return "Updated to \(tagName) successfully!"
    }
}
