import SwiftUI

struct ProfileEditorView: View {
    @EnvironmentObject var appState: AppState
    @State private var editingConfig: SlipnetConfig?

    var body: some View {
        ScrollView {
            if let config = appState.selectedConfig {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Profile Settings")
                        .font(.headline)

                    GroupBox("General") {
                        VStack(alignment: .leading, spacing: 10) {
                            LabeledField("Name") {
                                TextField("Profile name", text: binding(for: \.name))
                            }

                            LabeledField("URI") {
                                HStack {
                                    TextField("slipnet://...", text: binding(for: \.uri))
                                        .font(.system(size: 12, design: .monospaced))
                                    Button {
                                        if let clip = NSPasteboard.general.string(forType: .string) {
                                            var updated = config
                                            updated.uri = clip.trimmingCharacters(in: .whitespacesAndNewlines)
                                            appState.updateConfig(updated)
                                        }
                                    } label: {
                                        Image(systemName: "doc.on.clipboard")
                                    }
                                    .help("Paste from clipboard")
                                }
                            }
                        }
                        .padding(8)
                    }

                    GroupBox("Connection") {
                        VStack(alignment: .leading, spacing: 10) {
                            LabeledField("DNS Resolver") {
                                TextField("e.g., 1.1.1.1 or server-ip:port", text: binding(for: \.dnsResolver))
                            }

                            Toggle("Direct Mode (authoritative)", isOn: binding(for: \.isDirect))
                                .toggleStyle(.switch)

                            HStack(spacing: 16) {
                                LabeledField("Local Host") {
                                    TextField("127.0.0.1", text: binding(for: \.localHost))
                                }
                                LabeledField("Local Port") {
                                    TextField("Default from profile", text: binding(for: \.localPort))
                                }
                            }
                        }
                        .padding(8)
                    }

                    GroupBox("Advanced") {
                        VStack(alignment: .leading, spacing: 10) {
                            LabeledField("uTLS Fingerprint") {
                                TextField("e.g., Chrome_120, random, none", text: binding(for: \.utlsFingerprint))
                            }
                            Text("Examples: Chrome_120, Firefox_120, iOS_14, random, none")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("Weighted: \"3*Chrome_120,1*Firefox_120\"")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            LabeledField("Query Size (bytes)") {
                                TextField("Default: full capacity", text: binding(for: \.querySize))
                            }
                            Text("Presets: 100 (large), 80 (medium), 60 (small), 50 (minimum)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }

                    // Actions
                    HStack(spacing: 10) {
                        Button {
                            appState.selectedConfigID = nil
                        } label: {
                            Label("Save & Close", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)

                        Button {
                            appState.connect(config: config)
                        } label: {
                            Label("Save & Connect", systemImage: "bolt.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                        .controlSize(.large)
                        .disabled(config.uri.isEmpty)
                    }

                    Spacer()
                }
                .padding(16)
            } else {
                VStack {
                    Spacer()
                    Text("Select or create a profile")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func binding(for keyPath: WritableKeyPath<SlipnetConfig, String>) -> Binding<String> {
        Binding(
            get: { appState.selectedConfig?[keyPath: keyPath] ?? "" },
            set: { newValue in
                guard var config = appState.selectedConfig else { return }
                config[keyPath: keyPath] = newValue
                appState.updateConfig(config)
            }
        )
    }

    private func binding(for keyPath: WritableKeyPath<SlipnetConfig, Bool>) -> Binding<Bool> {
        Binding(
            get: { appState.selectedConfig?[keyPath: keyPath] ?? false },
            set: { newValue in
                guard var config = appState.selectedConfig else { return }
                config[keyPath: keyPath] = newValue
                appState.updateConfig(config)
            }
        )
    }
}

struct LabeledField<Content: View>: View {
    let label: String
    let content: () -> Content

    init(_ label: String, @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            content()
                .textFieldStyle(.roundedBorder)
        }
    }
}
