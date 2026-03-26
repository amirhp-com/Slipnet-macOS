import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingSettings = false
    @State private var showingScanSheet = false
    @State private var showingAdvancedRun = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 220, ideal: 220, max: 220)
        } detail: {
            DetailView(
                showingSettings: $showingSettings,
                showingScanSheet: $showingScanSheet,
                showingAdvancedRun: $showingAdvancedRun
            )
        }
        .navigationSplitViewStyle(.prominentDetail)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(appState)
                .frame(minWidth: 600, minHeight: 500)
        }
        .sheet(isPresented: $showingScanSheet) {
            ScanView()
                .environmentObject(appState)
                .frame(minWidth: 650, minHeight: 600)
        }
        .sheet(isPresented: $showingAdvancedRun) {
            AdvancedRunView()
                .environmentObject(appState)
                .frame(minWidth: 500, minHeight: 400)
        }
    }
}
