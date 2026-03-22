import SwiftUI

struct ScanView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var scanMode: ScanMode = .basic
    @State private var showFilePicker = false
    @State private var nslookupResult: String = ""
    @State private var nslookupTesting: Bool = false
    @State private var nslookupSuccess: Bool = false
    @State private var nslookupTestedIP: String = ""

    enum ScanMode: String, CaseIterable {
        case basic = "DNS Scanner"
        case e2e = "DNS Scanner + E2E"
        case quickScan = "Quick Scan"
        case prism = "Prism (Server-Verified)"
        case e2eOnly = "E2E Test Only"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("DNS Scanner")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            // Mode selector
            VStack(alignment: .leading, spacing: 6) {
                Text("Scan Mode")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Picker("Scan Mode", selection: $scanMode) {
                    ForEach(ScanMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal)
            }
            .padding(.top, 12)
            .onChange(of: scanMode) { _, mode in
                applyScanMode(mode)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Target
                    GroupBox("Target") {
                        VStack(alignment: .leading, spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Config URI")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Auto-extracts domain & pubkey from URI")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                TextField("slipnet://...", text: $appState.scanConfig.configURI)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Text("— or manually specify —")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, alignment: .center)

                            LabeledField("Domain") {
                                TextField("e.g., t.example.com", text: $appState.scanConfig.domain)
                            }
                            .disabled(!appState.scanConfig.configURI.isEmpty)

                            LabeledField("Public Key (hex)") {
                                TextField("Required for E2E/Prism", text: $appState.scanConfig.pubkey)
                            }
                            .disabled(!appState.scanConfig.configURI.isEmpty)
                        }
                        .padding(8)
                    }

                    // Resolvers
                    GroupBox("Resolvers") {
                        VStack(alignment: .leading, spacing: 10) {
                            LabeledField("IPs File") {
                                HStack {
                                    TextField("Path to file with IPs", text: $appState.scanConfig.ipsFile)
                                    Button("Browse...") {
                                        let panel = NSOpenPanel()
                                        panel.allowsMultipleSelection = false
                                        panel.canChooseDirectories = false
                                        if panel.runModal() == .OK, let url = panel.url {
                                            appState.scanConfig.ipsFile = url.path
                                        }
                                    }
                                }
                            }

                            LabeledField("Single IP (Quick Scan)") {
                                HStack {
                                    TextField("e.g., 8.8.8.8", text: $appState.scanConfig.singleIP)
                                    Button {
                                        testDNSWithNslookup()
                                    } label: {
                                        if nslookupTesting {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else {
                                            Label("Test", systemImage: "network")
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(appState.scanConfig.singleIP.trimmingCharacters(in: .whitespaces).isEmpty || nslookupTesting)
                                }
                            }

                            if !nslookupResult.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 6) {
                                        Image(systemName: nslookupSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundStyle(nslookupSuccess ? .green : .red)
                                        Text(nslookupSuccess ? "DNS is reachable" : "DNS test failed")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(nslookupSuccess ? .green : .red)
                                    }

                                    Text(nslookupResult)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                        .padding(6)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(RoundedRectangle(cornerRadius: 4).fill(.quaternary))
                                        .lineLimit(6)

                                    if nslookupSuccess {
                                        HStack(spacing: 8) {
                                            Button {
                                                let pasteboard = NSPasteboard.general
                                                pasteboard.clearContents()
                                                pasteboard.setString(nslookupTestedIP, forType: .string)
                                            } label: {
                                                Label("Copy IP", systemImage: "doc.on.doc")
                                            }
                                            .buttonStyle(.bordered)
                                            .controlSize(.small)

                                            Button {
                                                // Use this DNS in profile's DNS resolver field if a profile is selected
                                                if var config = appState.selectedConfig {
                                                    config.dnsResolver = nslookupTestedIP
                                                    appState.updateConfig(config)
                                                    nslookupResult = "Applied \(nslookupTestedIP) to current profile's DNS Resolver."
                                                } else {
                                                    nslookupResult += "\nNo profile selected to apply DNS to."
                                                }
                                            } label: {
                                                Label("Use in Profile", systemImage: "arrow.right.circle")
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(.cyan)
                                            .controlSize(.small)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(8)
                    }

                    // DNS Settings
                    GroupBox("DNS Settings") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 16) {
                                LabeledField("Timeout (ms)") {
                                    TextField("3000", text: $appState.scanConfig.timeout)
                                }
                                LabeledField("Concurrency") {
                                    TextField("100", text: $appState.scanConfig.concurrency)
                                }
                                LabeledField("Port") {
                                    TextField("53", text: $appState.scanConfig.port)
                                }
                            }

                            LabeledField("Query Size (bytes)") {
                                TextField("Default: full capacity", text: $appState.scanConfig.querySize)
                            }

                            Toggle("Use NoizDNS mode", isOn: $appState.scanConfig.useNoizDNS)
                                .toggleStyle(.switch)
                        }
                        .padding(8)
                    }

                    // E2E Settings (visible for E2E modes)
                    if scanMode == .e2e || scanMode == .e2eOnly {
                        GroupBox("E2E Test Settings") {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 16) {
                                    LabeledField("E2E Concurrency") {
                                        TextField("10", text: $appState.scanConfig.e2eConcurrency)
                                    }
                                    LabeledField("E2E Timeout (ms)") {
                                        TextField("15000", text: $appState.scanConfig.e2eTimeout)
                                    }
                                }

                                LabeledField("E2E Threshold (min DNS score 0-6)") {
                                    TextField("2", text: $appState.scanConfig.e2eThreshold)
                                }

                                LabeledField("Custom E2E Verification URL") {
                                    TextField("Default: gstatic generate_204", text: $appState.scanConfig.e2eURL)
                                }
                            }
                            .padding(8)
                        }
                    }

                    // Prism Settings
                    if scanMode == .prism {
                        GroupBox("Prism Settings") {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 16) {
                                    LabeledField("Probes per resolver") {
                                        TextField("5", text: $appState.scanConfig.probes)
                                    }
                                    LabeledField("Required passing") {
                                        TextField("2", text: $appState.scanConfig.threshold)
                                    }
                                }

                                LabeledField("Prism Timeout (ms)") {
                                    TextField("Same as timeout", text: $appState.scanConfig.prismTimeout)
                                }

                                LabeledField("Response Size (bytes)") {
                                    TextField("0 = server default, 200-4096 custom", text: $appState.scanConfig.responseSize)
                                }

                                Toggle("DNS Pre-filter (skip dead IPs)", isOn: $appState.scanConfig.prefilter)
                                    .toggleStyle(.switch)
                            }
                            .padding(8)
                        }
                    }

                    // Output
                    GroupBox("Output") {
                        LabeledField("Save results to file") {
                            HStack {
                                TextField("Optional output file", text: $appState.scanConfig.outputFile)
                                Button("Browse...") {
                                    let panel = NSSavePanel()
                                    panel.allowedContentTypes = [.text, .plainText]
                                    if panel.runModal() == .OK, let url = panel.url {
                                        appState.scanConfig.outputFile = url.path
                                    }
                                }
                            }
                        }
                        .padding(8)
                    }
                }
                .padding()
            }

            Divider()

            // Actions
            HStack {
                Button("Reset Defaults") {
                    appState.scanConfig = ScanConfig()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)

                Button {
                    appState.runScan()
                    dismiss()
                } label: {
                    Label("Start Scan", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(!canScan)
            }
            .padding()
        }
    }

    private var canScan: Bool {
        let sc = appState.scanConfig
        let hasTarget = !sc.configURI.isEmpty || !sc.domain.isEmpty
        let hasResolvers = !sc.ipsFile.isEmpty || !sc.singleIP.isEmpty || sc.configURI.isEmpty == false
        return hasTarget && (hasResolvers || scanMode == .e2eOnly)
    }

    private func testDNSWithNslookup() {
        let ip = appState.scanConfig.singleIP.trimmingCharacters(in: .whitespaces)
        guard !ip.isEmpty else { return }

        nslookupTesting = true
        nslookupResult = ""
        nslookupSuccess = false
        nslookupTestedIP = ip

        Task.detached {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/nslookup")
            proc.arguments = ["google.com", ip]

            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = pipe

            do {
                try proc.run()
                proc.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? "No output"
                let success = proc.terminationStatus == 0 && (output.lowercased().contains("address") || output.lowercased().contains("name"))

                await MainActor.run {
                    nslookupResult = output.trimmingCharacters(in: .whitespacesAndNewlines)
                    nslookupSuccess = success
                    nslookupTesting = false
                }
            } catch {
                await MainActor.run {
                    nslookupResult = "Failed to run nslookup: \(error.localizedDescription)"
                    nslookupSuccess = false
                    nslookupTesting = false
                }
            }
        }
    }

    private func applyScanMode(_ mode: ScanMode) {
        appState.scanConfig.enableE2E = false
        appState.scanConfig.e2eOnly = false
        appState.scanConfig.verifyPrism = false

        switch mode {
        case .basic:
            break
        case .e2e:
            appState.scanConfig.enableE2E = true
        case .quickScan:
            break
        case .prism:
            appState.scanConfig.verifyPrism = true
        case .e2eOnly:
            appState.scanConfig.e2eOnly = true
        }
    }
}
