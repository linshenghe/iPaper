import Foundation

enum PaperStatus: String, Codable, CaseIterable {
    case writing = "Writing"
    case submitted = "Submitted"
    case rnr = "R&R"
    case accepted = "Accepted"
    case published = "Published"
}

struct Paper: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var status: PaperStatus
    var journal: String
    var deadline: Date?
    var totalSeconds: Int
    var isRunning: Bool
    var sessionStart: Date?
    var createdAt: Date
    var updatedAt: Date
    var note: String
}
