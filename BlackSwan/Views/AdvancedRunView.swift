import SwiftUI

struct AdvancedRunView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var customArgs = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Run with Custom Options")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.escape)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox("Custom Command") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter arguments to pass to slipnet:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            TextField("e.g., --dns 1.1.1.1 --utls Chrome_120 slipnet://...", text: $customArgs)
                                .font(.system(size: 12, design: .monospaced))
                                .textFieldStyle(.roundedBorder)

                            if let config = appState.selectedConfig, !config.uri.isEmpty {
                                Button("Fill from selected profile") {
                                    customArgs = config.buildArguments().joined(separator: " ")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }

                            Button("Paste URI from clipboard") {
                                if let clip = NSPasteboard.general.string(forType: .string) {
                                    let trimmed = clip.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if customArgs.isEmpty {
                                        customArgs = trimmed
                                    } else {
                                        customArgs += " " + trimmed
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(8)
                    }

                    GroupBox("Quick Reference") {
                        VStack(alignment: .leading, spacing: 4) {
                            referenceRow("--dns HOST[:PORT]", "Custom DNS resolver")
                            referenceRow("--direct", "Connect directly (authoritative)")
                            referenceRow("--port PORT", "Local SOCKS5 port")
                            referenceRow("--host HOST", "Local listen address (0.0.0.0 for LAN)")
                            referenceRow("--utls FINGERPRINT", "TLS fingerprint")
                            referenceRow("--query-size BYTES", "Max query payload (50-100)")

                            Divider().padding(.vertical, 4)

                            Text("Example:")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("--dns 1.1.1.1 --utls Chrome_120 slipnet://BASE64...")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                    }

                    // Command preview
                    if !customArgs.isEmpty {
                        GroupBox("Command Preview") {
                            Text("\(appState.slipnetPath.isEmpty ? "slipnet" : appState.slipnetPath) \(customArgs)")
                                .font(.system(size: 11, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                        }
                    }
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Button {
                    let args = parseArguments(customArgs)
                    appState.connectWithCustomArgs(args)
                    dismiss()
                } label: {
                    Label("Run", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(customArgs.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
    }

    private func referenceRow(_ flag: String, _ desc: String) -> some View {
        HStack(alignment: .top) {
            Text(flag)
                .font(.system(size: 10, design: .monospaced))
                .frame(width: 180, alignment: .leading)
            Text(desc)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func parseArguments(_ string: String) -> [String] {
        // Simple argument parser that handles quoted strings
        var args: [String] = []
        var current = ""
        var inQuote = false
        var quoteChar: Character = "\""

        for char in string {
            if inQuote {
                if char == quoteChar {
                    inQuote = false
                } else {
                    current.append(char)
                }
            } else if char == "\"" || char == "'" {
                inQuote = true
                quoteChar = char
            } else if char == " " {
                if !current.isEmpty {
                    args.append(current)
                    current = ""
                }
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            args.append(current)
        }
        return args
    }
}
