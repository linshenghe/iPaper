import Foundation

struct AppData: Codable, Equatable {
    var papers: [Paper] = []
    var reviews: [Review] = []
    var sessions: [Session] = []
    var settings: AppSettings = AppSettings()
}
