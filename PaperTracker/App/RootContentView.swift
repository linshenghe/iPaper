import SwiftUI

struct RootContentView: View {
    @EnvironmentObject private var dataStore: DataStore
    @State private var sidebarSelection: SidebarNavigation = .allPapers

    var body: some View {
        VStack(spacing: 0) {
            TopStatusStripView(dataStore: dataStore)

            NavigationSplitView {
                SidebarView(
                    selection: $sidebarSelection,
                    dataStore: dataStore
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
    }
}

#Preview {
    RootContentView()
        .environmentObject(AppEnvironment.bootstrap().dataStore)
}
