import SwiftUI

struct TerminalView: View {
    @EnvironmentObject var appState: AppState
    @State private var autoScroll = true
    @State private var customCommand = ""

    var body: some View {
        VStack(spacing: 0) {
            // Terminal header
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(.red).frame(width: 10, height: 10)
                    Circle().fill(.yellow).frame(width: 10, height: 10)
                    Circle().fill(.green).frame(width: 10, height: 10)
                }

                Text("Terminal Output")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.switch)
                    .controlSize(.mini)

                Button {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(appState.terminalOutput, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .help("Copy output")
                .buttonStyle(.borderless)

                Button {
                    appState.clearOutput()
                } label: {
                    Image(systemName: "trash")
                }
                .help("Clear output")
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Terminal content
            ScrollViewReader { proxy in
                ScrollView {
                    Text(appState.terminalOutput.isEmpty ? "Ready. Select a profile and click Connect, or paste a URI from clipboard.\n" : appState.terminalOutput)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(appState.terminalOutput.isEmpty ? .secondary : .primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .id("terminalBottom")
                }
                .background(Color(red: 0.07, green: 0.07, blue: 0.1))
                .onChange(of: appState.terminalOutput) { _, _ in
                    if autoScroll {
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo("terminalBottom", anchor: .bottom)
                        }
                    }
                }
            }

            Divider()

            // Custom command runner
            HStack(spacing: 8) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.cyan)

                TextField("slipnet command args (e.g. --version, --help, scan ...)", text: $customCommand)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .onSubmit {
                        runCustomCommand()
                    }

                Button {
                    runCustomCommand()
                } label: {
                    Image(systemName: "play.fill")
                }
                .buttonStyle(.borderless)
                .tint(.cyan)
                .disabled(customCommand.trimmingCharacters(in: .whitespaces).isEmpty || appState.slipnetPath.isEmpty)
                .help("Run command via slipnet")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.07, green: 0.07, blue: 0.1))
        }
    }

    private func runCustomCommand() {
        let cmd = customCommand.trimmingCharacters(in: .whitespaces)
        guard !cmd.isEmpty else { return }

        let args = cmd.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        appState.runCustomCommand(args)
        customCommand = ""
    }
}
