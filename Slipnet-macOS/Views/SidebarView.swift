import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingImportAlert = false
    @State private var importText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Image(systemName: "network.badge.shield.half.filled")
                    .font(.system(size: 32))
                    .foregroundStyle(.cyan)
                Text("Slipnet-macOS")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Slipnet macOS")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)

            Divider()

            // Connection status badge
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(appState.connectionStatus.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)

            Divider()

            // Profile list
            List(selection: $appState.selectedConfigID) {
                Section("Profiles") {
                    ForEach(appState.configs) { config in
                        ProfileRow(config: config)
                            .tag(config.id)
                            .contextMenu {
                                Button("Duplicate") {
                                    appState.duplicateConfig(config)
                                }
                                Button("Delete", role: .destructive) {
                                    appState.deleteConfig(config)
                                }
                            }
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Bottom actions
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Button {
                        let config = SlipnetConfig()
                        appState.addConfig(config)
                        appState.selectedConfigID = config.id
                    } label: {
                        Label("Add", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        showingImportAlert = true
                    } label: {
                        Label("Import", systemImage: "doc.on.clipboard")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Button {
                    appState.pasteAndConnect()
                } label: {
                    Label("Quick Connect from Clipboard", systemImage: "clipboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.cyan)

                // Branding
                Text("Developed by amirhp.com")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            .padding(12)
        }
        .frame(minWidth: 220)
        .alert("Import Profile URI", isPresented: $showingImportAlert) {
            TextField("slipnet://...", text: $importText)
            Button("Import") {
                importProfile()
            }
            Button("Cancel", role: .cancel) {
                importText = ""
            }
        } message: {
            Text("Paste a slipnet:// or slipnet-enc:// URI")
        }
    }

    private var statusColor: Color {
        switch appState.connectionStatus {
        case .disconnected: return .gray
        case .connecting: return .yellow
        case .connected: return .green
        case .scanning: return .blue
        case .error: return .red
        }
    }

    private func importProfile() {
        let trimmed = importText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("slipnet://") || trimmed.hasPrefix("slipnet-enc://") else {
            appState.appendOutput("[Slipnet-macOS] Invalid URI format. Must start with slipnet:// or slipnet-enc://\n")
            importText = ""
            return
        }
        var config = SlipnetConfig()
        config.uri = trimmed
        config.name = "Imported (\(Date().formatted(date: .abbreviated, time: .shortened)))"
        appState.addConfig(config)
        appState.selectedConfigID = config.id
        importText = ""
    }
}

struct ProfileRow: View {
    let config: SlipnetConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(config.name)
                .font(.system(.body, design: .default))
                .lineLimit(1)
            if !config.uri.isEmpty {
                Text(String(config.uri.prefix(40)) + (config.uri.count > 40 ? "..." : ""))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("No URI configured")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
