import Combine
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let dataStore: DataStore
    let timerController: PaperTimerController

    static func bootstrap() -> AppEnvironment {
        let dataStore = DataStore(dataURL: DataStore.defaultDataURL())
        let timerController = PaperTimerController(dataStore: dataStore)
        return AppEnvironment(dataStore: dataStore, timerController: timerController)
    }

    init(dataStore: DataStore, timerController: PaperTimerController) {
        self.dataStore = dataStore
        self.timerController = timerController
    }
}
