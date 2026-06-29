import Combine
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let dataStore: DataStore

    static func bootstrap() -> AppEnvironment {
        AppEnvironment(dataStore: DataStore(dataURL: DataStore.defaultDataURL()))
    }

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
}
