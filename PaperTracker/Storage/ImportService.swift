import Combine
import Foundation

@MainActor
final class ImportService: ObservableObject {
    @Published var legacyPreview: LegacyPreview?
    @Published var importError: String?

    private let dataStore: DataStore

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    // MARK: - Preview

    struct LegacyPreview {
        let paperCount: Int
        let reviewCount: Int
        let sessionCount: Int
        let warnings: [String]
        fileprivate let result: MigrationResult
    }

    func previewLegacyJSON(at url: URL) {
        importError = nil
        legacyPreview = nil

        guard let raw = try? Data(contentsOf: url) else {
            importError = "无法读取所选文件。"
            return
        }

        do {
            let result = try DataMigration.migrateLegacyJSON(raw)
            legacyPreview = LegacyPreview(
                paperCount: result.data.papers.count,
                reviewCount: result.data.reviews.count,
                sessionCount: result.data.sessions.count,
                warnings: result.warnings,
                result: result
            )
        } catch {
            importError = "导入失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Import

    /// Import when library is empty — direct replace.
    func importIntoEmptyLibrary() -> [String] {
        guard let preview = legacyPreview else {
            importError = "没有可导入的数据。"
            return []
        }
        dataStore.appData = preview.result.data
        do {
            try dataStore.save()
        } catch {
            importError = "保存导入数据失败：\(error.localizedDescription)"
        }
        legacyPreview = nil
        return preview.warnings
    }

    /// Merge into existing library — keep existing IDs, add new ones.
    func mergeIntoLibrary() -> [String] {
        guard let preview = legacyPreview else {
            importError = "没有可导入的数据。"
            return []
        }
        let existingPaperIDs = Set(dataStore.appData.papers.map(\.id))
        let existingReviewIDs = Set(dataStore.appData.reviews.map(\.id))
        let existingSessionIDs = Set(dataStore.appData.sessions.map(\.id))

        var merged = dataStore.appData
        for paper in preview.result.data.papers where !existingPaperIDs.contains(paper.id) {
            merged.papers.append(paper)
        }
        for review in preview.result.data.reviews where !existingReviewIDs.contains(review.id) {
            merged.reviews.append(review)
        }
        for session in preview.result.data.sessions where !existingSessionIDs.contains(session.id) {
            merged.sessions.append(session)
        }
        merged.settings.hasImportedLegacyData = true

        dataStore.appData = merged
        do {
            try dataStore.save()
        } catch {
            importError = "保存合并数据失败：\(error.localizedDescription)"
        }
        legacyPreview = nil
        return preview.warnings
    }
}
