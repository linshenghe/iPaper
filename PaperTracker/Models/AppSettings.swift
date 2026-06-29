import Foundation

struct AppSettings: Codable, Equatable {
    var lastBackupAt: Date?
    var hasImportedLegacyData: Bool = false
    var preferredExportDirectoryBookmark: Data?
}
