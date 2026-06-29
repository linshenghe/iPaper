import SwiftUI

@main
struct PaperTrackerApp: App {
    @StateObject private var environment = AppEnvironment.bootstrap()

    var body: some Scene {
        WindowGroup {
            RootContentView()
                .environmentObject(environment)
                .environmentObject(environment.dataStore)
                .environmentObject(environment.timerController)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                // ponytail: Settings handled via sidebar sheet, not system prefs window
            }
        }
    }
}
