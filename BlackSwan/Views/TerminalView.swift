import SwiftUI

struct TerminalView: View {
    @EnvironmentObject var appState: AppState
    @State private var autoScroll = true

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
        }
    }
}
