import SwiftUI

struct RootContentView: View {
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var timerController: PaperTimerController
    @State private var sidebarSelection: SidebarNavigation = .allPapers
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            TopStatusStripView(dataStore: dataStore)

            NavigationSplitView {
                SidebarView(
                    selection: $sidebarSelection,
                    dataStore: dataStore,
                    onSettings: { showSettings = true }
                )
                .navigationSplitViewColumnWidth(min: 200, ideal: 220)
            } detail: {
                DetailContainerView(
                    selection: sidebarSelection,
                    dataStore: dataStore
                )
            }
        }
        .alert(item: $dataStore.activeError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .default(Text("好"))
            )
        }
        .onAppear {
            timerController.recoverIfNeeded()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(dataStore: dataStore)
        }
    }
}

#Preview {
    RootContentView()
        .environmentObject(AppEnvironment.bootstrap().dataStore)
        .environmentObject(AppEnvironment.bootstrap().timerController)
}
