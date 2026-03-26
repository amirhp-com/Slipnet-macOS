import SwiftUI

@main
struct SlipnetMacOSApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Profile") {
                    let config = SlipnetConfig()
                    appState.addConfig(config)
                    appState.selectedConfigID = config.id
                }
                .keyboardShortcut("n")
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
