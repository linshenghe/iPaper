import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Wraps ImportService with NSOpenPanel for legacy data import.
struct ImportExportPanel: View {
    @ObservedObject var dataStore: DataStore
    @StateObject private var importService: ImportService

    init(dataStore: DataStore) {
        self.dataStore = dataStore
        _importService = StateObject(wrappedValue: ImportService(dataStore: dataStore))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.formSectionGap) {
            // Import section
            VStack(alignment: .leading, spacing: AppSpacing.fieldGap) {
                Text("Import")
                    .font(AppTypography.sectionTitle)

                Text("从旧版 iPaper 网页版导入数据（JSON 格式）")
                    .font(AppTypography.bodySecondary)
                    .foregroundColor(AppColors.textTertiary)

                SecondaryButton(title: "选择旧数据文件...") {
                    selectLegacyFile()
                }

                if let preview = importService.legacyPreview {
                    VStack(alignment: .leading, spacing: AppSpacing.space3) {
                        Text("预览：\(preview.paperCount) 篇论文, \(preview.reviewCount) 条审稿, \(preview.sessionCount) 条日志")
                            .font(AppTypography.bodySecondary)

                        if !preview.warnings.isEmpty {
                            ForEach(preview.warnings.prefix(5), id: \.self) { w in
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 10))
                                    Text(w)
                                        .font(AppTypography.metaLabel)
                                }
                                .foregroundColor(AppColors.warning)
                            }
                        }

                        HStack(spacing: AppSpacing.space4) {
                            if dataStore.appData.papers.isEmpty {
                                PrimaryButton(title: "导入") {
                                    _ = importService.importIntoEmptyLibrary()
                                }
                            } else {
                                SecondaryButton(title: "合并到当前库") {
                                    _ = importService.mergeIntoLibrary()
                                }
                            }
                        }
                    }
                }

                if let err = importService.importError {
                    Text(err)
                        .font(AppTypography.metaLabel)
                        .foregroundColor(AppColors.danger)
                }
            }

            Divider()

            // Export section
            VStack(alignment: .leading, spacing: AppSpacing.fieldGap) {
                Text("Export")
                    .font(AppTypography.sectionTitle)

                Text("导出为三个 CSV 文件（papers / reviews / sessions）")
                    .font(AppTypography.bodySecondary)
                    .foregroundColor(AppColors.textTertiary)

                SecondaryButton(title: "导出 CSV...") {
                    exportCSV()
                }
            }
        }
    }

    // MARK: - Actions

    private func selectLegacyFile() {
        let panel = NSOpenPanel()
        panel.title = "选择旧版 JSON 数据"
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.urls.first else { return }
        importService.previewLegacyJSON(at: url)
    }

    private func exportCSV() {
        let panel = NSOpenPanel()
        panel.title = "选择导出目录"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let dir = panel.urls.first else { return }

        let csv = CSVExporter.exportAll(data: dataStore.appData)
        let files: [(String, String)] = [
            ("papers.csv", csv.papersCSV),
            ("reviews.csv", csv.reviewsCSV),
            ("sessions.csv", csv.sessionsCSV),
        ]
        for (name, content) in files {
            try? content.write(to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }
    }
}
