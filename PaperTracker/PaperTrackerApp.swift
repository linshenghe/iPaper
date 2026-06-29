//
//  PaperTrackerApp.swift
//  PaperTracker
//
//  Created by 何林晟 on 2026/6/29.
//

import SwiftUI

@main
struct PaperTrackerApp: App {
    @StateObject private var environment = AppEnvironment.bootstrap()

    var body: some Scene {
        WindowGroup {
            RootContentView()
                .environmentObject(environment)
                .environmentObject(environment.dataStore)
        }
    }
}
