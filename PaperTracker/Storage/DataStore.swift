import Combine
import Foundation

@MainActor
final class DataStore: ObservableObject {
    @Published var appData = AppData()
    @Published var activeError: ErrorAlertState?

    private let dataURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(dataURL: URL) {
        self.dataURL = dataURL
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        createDirectoryIfNeeded()
        load()
    }

    // MARK: - Load

    private func createDirectoryIfNeeded() {
        let dir = dataURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(
                at: dir,
                withIntermediateDirectories: true
            )
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: dataURL.path) else {
            // ponytail: empty AppData is fine — no file just means fresh start
            return
        }

        guard let raw = try? Data(contentsOf: dataURL) else {
            activeError = .loadFailed("无法读取数据文件。请检查文件权限。")
            return
        }

        do {
            appData = try decoder.decode(AppData.self, from: raw)
        } catch {
            activeError = .loadFailed("数据文件格式错误：\(error.localizedDescription)")
            // Keep current in-memory state; do not overwrite file
        }
    }

    // MARK: - Save

    func save() throws {
        let raw = try encoder.encode(appData)
        try raw.write(to: dataURL, options: .atomic)
        activeError = nil
    }

    // MARK: - Convenience data URL

    static func defaultDataURL() -> URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        return appSupport
            .appendingPathComponent("PaperTracker", isDirectory: true)
            .appendingPathComponent("data.json")
    }
}
