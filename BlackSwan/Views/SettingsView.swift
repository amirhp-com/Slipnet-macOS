import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: SettingsTab = .general

    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case connection = "Connection"
        case scan = "Scanner"
        case update = "Update"
        case about = "About"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: iconForTab(tab))
                                .font(.title3)
                            Text(tab.rawValue)
                                .font(.caption)
                        }
                        .frame(width: 80, height: 50)
                        .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .general:
                        generalSettings
                    case .connection:
                        connectionDefaults
                    case .scan:
                        scannerDefaults
                    case .update:
                        updateSection
                    case .about:
                        aboutSection
                    }
                }
                .padding(20)
            }

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
            }
            .padding()
        }
    }

    private func iconForTab(_ tab: SettingsTab) -> String {
        switch tab {
        case .general: return "gear"
        case .connection: return "network"
        case .scan: return "magnifyingglass"
        case .update: return "arrow.down.circle"
        case .about: return "info.circle"
        }
    }

    // MARK: - General Settings

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("General Settings")
                .font(.title3)
                .fontWeight(.semibold)

            GroupBox("SlipNet Binary") {
                VStack(alignment: .leading, spacing: 10) {
                    LabeledField("Path to slipnet") {
                        HStack {
                            TextField("/path/to/slipnet", text: $appState.slipnetPath)
                                .font(.system(size: 12, design: .monospaced))
                            Button("Browse...") {
                                let panel = NSOpenPanel()
                                panel.allowsMultipleSelection = false
                                panel.canChooseDirectories = false
                                panel.canChooseFiles = true
                                panel.message = "Select the slipnet binary"
                                if panel.runModal() == .OK, let url = panel.url {
                                    appState.setSlipnetPath(url.path)
                                }
                            }
                        }
                    }

                    if !appState.slipnetPath.isEmpty {
                        if FileManager.default.isExecutableFile(atPath: appState.slipnetPath) {
                            Label("Binary found and executable", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        } else {
                            Label("Binary not found or not executable", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }

                    Button("Detect Automatically") {
                        appState.setSlipnetPath("")
                        // Re-trigger detection
                        let appStateRef = appState
                        let candidates = [
                            Bundle.main.bundlePath.replacingOccurrences(of: "/BlackSwan.app", with: "") + "/slipnet",
                            NSHomeDirectory() + "/Documents/WorkStuff/VPN-slipnet/slipnet",
                            "/usr/local/bin/slipnet",
                            "/opt/homebrew/bin/slipnet"
                        ]
                        for path in candidates {
                            if FileManager.default.isExecutableFile(atPath: path) {
                                appStateRef.setSlipnetPath(path)
                                break
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(8)
            }
        }
    }

    // MARK: - Connection Defaults

    @AppStorage("default.dnsResolver") private var defaultDNS = ""
    @AppStorage("default.localHost") private var defaultHost = "127.0.0.1"
    @AppStorage("default.localPort") private var defaultPort = ""
    @AppStorage("default.utls") private var defaultUTLS = ""
    @AppStorage("default.querySize") private var defaultQuerySize = ""
    @AppStorage("default.isDirect") private var defaultDirect = false

    private var connectionDefaults: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connection Defaults")
                .font(.title3)
                .fontWeight(.semibold)

            Text("These defaults apply when creating new profiles.")
                .font(.caption)
                .foregroundStyle(.secondary)

            GroupBox("Network") {
                VStack(alignment: .leading, spacing: 10) {
                    LabeledField("Default DNS Resolver") {
                        TextField("e.g., 1.1.1.1", text: $defaultDNS)
                    }

                    Toggle("Default to Direct Mode", isOn: $defaultDirect)
                        .toggleStyle(.switch)

                    HStack(spacing: 16) {
                        LabeledField("Default Local Host") {
                            TextField("127.0.0.1", text: $defaultHost)
                        }
                        LabeledField("Default Local Port") {
                            TextField("From profile", text: $defaultPort)
                        }
                    }
                }
                .padding(8)
            }

            GroupBox("System SOCKS Proxy") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("When enabled, routes all macOS traffic through the SOCKS5 proxy.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LabeledField("Network Interface") {
                        TextField("Wi-Fi", text: $appState.socksProxyInterface)
                    }
                    Text("Common values: Wi-Fi, Ethernet, Thunderbolt Bridge")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    HStack(spacing: 10) {
                        Button {
                            appState.enableSOCKSProxy()
                        } label: {
                            Label("Enable Proxy", systemImage: "globe")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .disabled(appState.connectionStatus != .connected)

                        Button {
                            appState.disableSOCKSProxy()
                        } label: {
                            Label("Disable Proxy", systemImage: "globe.badge.chevron.backward")
                        }
                        .buttonStyle(.bordered)
                    }

                    if appState.socksProxyEnabled {
                        Label("SOCKS proxy is active", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                .padding(8)
            }

            GroupBox("TLS & Query") {
                VStack(alignment: .leading, spacing: 10) {
                    LabeledField("Default uTLS Fingerprint") {
                        Picker("", selection: $defaultUTLS) {
                            Text("Default (random)").tag("")
                            Text("Chrome_120").tag("Chrome_120")
                            Text("Firefox_120").tag("Firefox_120")
                            Text("iOS_14").tag("iOS_14")
                            Text("random").tag("random")
                            Text("none").tag("none")
                        }
                    }

                    LabeledField("Default Query Size") {
                        Picker("", selection: $defaultQuerySize) {
                            Text("Full capacity (default)").tag("")
                            Text("100 - Large").tag("100")
                            Text("80 - Medium").tag("80")
                            Text("60 - Small").tag("60")
                            Text("50 - Minimum").tag("50")
                        }
                    }
                }
                .padding(8)
            }
        }
    }

    // MARK: - Scanner Defaults

    @AppStorage("scan.timeout") private var scanTimeout = "3000"
    @AppStorage("scan.concurrency") private var scanConcurrency = "100"
    @AppStorage("scan.e2eConcurrency") private var scanE2EConcurrency = "10"
    @AppStorage("scan.e2eTimeout") private var scanE2ETimeout = "15000"
    @AppStorage("scan.probes") private var scanProbes = "5"
    @AppStorage("scan.threshold") private var scanThreshold = "2"

    private var scannerDefaults: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Scanner Defaults")
                .font(.title3)
                .fontWeight(.semibold)

            GroupBox("DNS Scan") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 16) {
                        LabeledField("Timeout (ms)") {
                            TextField("3000", text: $scanTimeout)
                        }
                        LabeledField("Concurrency") {
                            TextField("100", text: $scanConcurrency)
                        }
                    }
                }
                .padding(8)
            }

            GroupBox("E2E Test") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 16) {
                        LabeledField("E2E Concurrency") {
                            TextField("10", text: $scanE2EConcurrency)
                        }
                        LabeledField("E2E Timeout (ms)") {
                            TextField("15000", text: $scanE2ETimeout)
                        }
                    }
                }
                .padding(8)
            }

            GroupBox("Prism") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 16) {
                        LabeledField("Probes per resolver") {
                            TextField("5", text: $scanProbes)
                        }
                        LabeledField("Required passing") {
                            TextField("2", text: $scanThreshold)
                        }
                    }
                }
                .padding(8)
            }
        }
    }

    // MARK: - Update

    private var updateSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Update SlipNet Core")
                .font(.title3)
                .fontWeight(.semibold)

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Download the latest slipnet binary from the official GitHub repository.")
                        .font(.callout)

                    HStack {
                        Link("github.com/anonvector/SlipNet",
                             destination: URL(string: "https://github.com/anonvector/SlipNet")!)
                            .font(.caption)

                        Spacer()
                    }

                    if !appState.updateStatus.isEmpty {
                        Text(appState.updateStatus)
                            .font(.caption)
                            .foregroundStyle(appState.updateStatus.contains("failed") || appState.updateStatus.contains("Error") ? .red : .green)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary))
                    }

                    Button {
                        appState.updateSlipnet()
                    } label: {
                        if appState.isUpdating {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.trailing, 4)
                            Text("Updating...")
                        } else {
                            Label("Check for Updates", systemImage: "arrow.down.circle")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(appState.isUpdating)
                }
                .padding(8)
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "network.badge.shield.half.filled")
                .font(.system(size: 64))
                .foregroundStyle(.cyan)

            Text("BlackSwan")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Slipnet macOS")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("A VPN client with DNS tunneling (DNSTT, NoizDNS & Slipstream),\nNaiveProxy, SSH, Tor, and DoH support — featuring a built-in DNS scanner.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)

            Divider()
                .frame(width: 200)

            VStack(spacing: 4) {
                Text("Developed by")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Link("amirhp.com", destination: URL(string: "https://amirhp.com")!)
                    .font(.callout)
                    .fontWeight(.medium)
            }

            VStack(spacing: 4) {
                Text("SlipNet Core")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Link("github.com/anonvector/SlipNet", destination: URL(string: "https://github.com/anonvector/SlipNet")!)
                    .font(.caption)
            }

            Text("v1.0.0")
                .font(.caption2)
                .foregroundStyle(.quaternary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
