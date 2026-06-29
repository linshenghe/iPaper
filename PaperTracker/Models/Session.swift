import Foundation

enum SessionType: String, Codable, CaseIterable {
    case paper = "Paper"
    case review = "Review"
}

enum SessionSource: String, Codable {
    case timer = "Timer"
    case manual = "Manual"
}

struct Session: Identifiable, Codable, Equatable {
    let id: String
    var type: SessionType
    var targetId: String
    var targetName: String
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int
    var note: String
    var source: SessionSource
}
