import SwiftUI

struct RootContentView: View {
    @EnvironmentObject private var dataStore: DataStore

    var body: some View {
        Text("iPaper")
            .font(.title)
            .alert(item: $dataStore.activeError) { error in
                Alert(
                    title: Text(error.title),
                    message: Text(error.message),
                    dismissButton: .default(Text("好"))
                )
            }
    }
}
