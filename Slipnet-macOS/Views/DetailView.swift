import SwiftUI

struct DetailView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showingSettings: Bool
    @Binding var showingScanSheet: Bool
    @Binding var showingAdvancedRun: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar area
            toolbar
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.bar)

            Divider()

            // Main content split
            if appState.selectedConfigID != nil {
                HSplitView {
                    // Left: Profile editor
                    ProfileEditorView()
                        .frame(minWidth: 280, idealWidth: 320)

                    // Right: Terminal
                    TerminalView()
                        .frame(minWidth: 350)
                }
            } else {
                // No selection - show terminal only
                VStack {
                    TerminalView()
                }
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            // Connection controls
            Group {
                if appState.isRunning {
                    Button {
                        appState.stop()
                    } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .tint(.red)
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        if let config = appState.selectedConfig {
                            appState.connect(config: config)
                        }
                    } label: {
                        Label("Connect", systemImage: "bolt.fill")
                    }
                    .tint(.green)
                    .buttonStyle(.borderedProminent)
                    .disabled(appState.selectedConfig == nil)
                }
            }

            Button {
                showingAdvancedRun = true
            } label: {
                Label("Run with Options", systemImage: "terminal")
            }
            .buttonStyle(.bordered)

            Button {
                appState.pasteAndConnect()
            } label: {
                Label("Paste & Connect", systemImage: "clipboard")
            }
            .buttonStyle(.bordered)

            Divider()
                .frame(height: 20)

            Button {
                showingScanSheet = true
            } label: {
                Label("DNS Scanner", systemImage: "magnifyingglass")
            }
            .buttonStyle(.bordered)

            // SOCKS Proxy toggle
            if appState.connectionStatus == .connected {
                if appState.socksProxyEnabled {
                    Button {
                        appState.toggleSOCKSProxy()
                    } label: {
                        Label("Proxy On", systemImage: "globe.badge.chevron.backward")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                } else {
                    Button {
                        appState.toggleSOCKSProxy()
                    } label: {
                        Label("System Proxy", systemImage: "globe")
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer()

            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                    .shadow(color: statusColor.opacity(0.6), radius: 4)
                Text(appState.connectionStatus.rawValue)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(.ultraThinMaterial))

            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gear")
            }
            .buttonStyle(.bordered)
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
}
