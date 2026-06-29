import Foundation

enum ReviewStatus: String, Codable, CaseIterable {
    case inProgress = "In Progress"
    case completed = "Completed"
}

struct Review: Identifiable, Codable, Equatable {
    let id: String
    var journal: String
    var deadline: Date?
    var status: ReviewStatus
    var note: String
    var createdAt: Date
    var updatedAt: Date
}
