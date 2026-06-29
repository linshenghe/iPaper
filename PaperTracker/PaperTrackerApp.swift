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
        .defaultSize(width: 900, height: 600)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appSettings) {
                // ponytail: Settings handled via sidebar sheet, not system prefs window
            }
        }
    }
}
