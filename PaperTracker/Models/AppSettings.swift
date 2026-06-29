import Foundation

struct AppSettings: Codable, Equatable {
    var lastBackupAt: Date?
    var lastSavedAt: Date?
    var hasImportedLegacyData: Bool = false
    var preferredExportDirectoryBookmark: Data?
}
