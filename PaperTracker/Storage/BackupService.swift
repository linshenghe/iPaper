import AppKit
import Combine
import Foundation
import UniformTypeIdentifiers

@MainActor
final class BackupService: ObservableObject {
    @Published var restorePreview: RestorePreview?
    @Published var error: String?

    private let dataStore: DataStore

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    // MARK: - Backup

    func backup() {
        let panel = NSSavePanel()
        panel.title = "备份数据"
        panel.nameFieldStringValue = "papertracker-backup-\(dateString()).json"
        panel.allowedContentTypes = [.json]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let raw = try encoder.encode(dataStore.appData)
            try raw.write(to: url)
            dataStore.appData.settings.lastBackupAt = Date()
            try dataStore.save()
        } catch {
            self.error = "备份失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Restore

    struct RestorePreview {
        let paperCount: Int
        let reviewCount: Int
        let sessionCount: Int
        let backupDate: Date?
        fileprivate let data: AppData
    }

    func previewRestoreFile() {
        let panel = NSOpenPanel()
        panel.title = "选择备份文件"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.urls.first else { return }

        do {
            let raw = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(AppData.self, from: raw)
            restorePreview = RestorePreview(
                paperCount: decoded.papers.count,
                reviewCount: decoded.reviews.count,
                sessionCount: decoded.sessions.count,
                backupDate: decoded.settings.lastBackupAt,
                data: decoded
            )
        } catch {
            self.error = "无法读取备份文件：\(error.localizedDescription)"
        }
    }

    func confirmRestore() {
        guard let preview = restorePreview else { return }
        dataStore.appData = preview.data
        do {
            try dataStore.save()
        } catch {
            self.error = "恢复数据失败：\(error.localizedDescription)"
        }
        restorePreview = nil
    }

    // MARK: - Helpers

    private func dateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}
