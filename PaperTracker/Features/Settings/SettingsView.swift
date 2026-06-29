import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var dataStore: DataStore
    @StateObject private var backupService: BackupService

    // AI settings
    @AppStorage("aiBaseURL") private var aiBaseURL = "https://api.openai.com/v1"
    @AppStorage("aiModel") private var aiModel = "gpt-4o"
    @State private var apiKeyInput = ""
    @State private var keySaved = false
    @State private var keyError: String?
    @State private var connectionTestResult: String?
    @State private var isTestingConnection = false

    private let keychain = KeychainService()
    private let aiService = AIService()

    init(dataStore: DataStore) {
        self.dataStore = dataStore
        _backupService = StateObject(wrappedValue: BackupService(dataStore: dataStore))
    }

    var body: some View {
        ScrollView {
            // Close button
            HStack {
                Spacer()
                Button("Close") { dismiss() }
                    .font(AppTypography.buttonLabel)
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.bottom, AppSpacing.space4)

            VStack(alignment: .leading, spacing: AppSpacing.formSectionGap) {
                dataSection
                Divider()
                aiSection
                Divider()
                appSection
            }
            .padding(AppSpacing.sheetPadding)
        }
        .frame(minWidth: 460, idealWidth: 480)
    }

    // MARK: - Data section

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.fieldGap) {
            Text("Data")
                .font(AppTypography.sectionTitle)

            HStack {
                Text("数据位置")
                    .font(AppTypography.bodySecondary)
                    .foregroundColor(AppColors.textSecondary)
                Text(DataStore.defaultDataURL().path)
                    .font(AppTypography.metaLabel)
                    .foregroundColor(AppColors.textTertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            HStack(spacing: AppSpacing.space4) {
                SecondaryButton(title: "备份...") {
                    backupService.backup()
                }
                SecondaryButton(title: "恢复...") {
                    backupService.previewRestoreFile()
                }
            }

            if let preview = backupService.restorePreview {
                VStack(alignment: .leading, spacing: AppSpacing.space3) {
                    Text("将覆盖当前数据：\(preview.paperCount) 篇论文, \(preview.reviewCount) 条审稿, \(preview.sessionCount) 条日志")
                        .font(AppTypography.bodySecondary)
                        .foregroundColor(AppColors.danger)

                    HStack(spacing: AppSpacing.space4) {
                        PrimaryButton(title: "确认恢复") {
                            backupService.confirmRestore()
                        }
                        Button("取消") {
                            backupService.restorePreview = nil
                        }
                    }
                }
                .padding(AppSpacing.space4)
                .background(AppColors.dangerSoft)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.control))
            }

            if let err = backupService.error {
                Text(err)
                    .font(AppTypography.metaLabel)
                    .foregroundColor(AppColors.danger)
            }

            ImportExportPanel(dataStore: dataStore)
        }
    }

    // MARK: - AI section

    private var aiSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.fieldGap) {
            Text("AI")
                .font(AppTypography.sectionTitle)

            VStack(alignment: .leading, spacing: 4) {
                Text("Base URL").font(AppTypography.fieldLabel)
                TextField("https://api.openai.com/v1", text: $aiBaseURL)
                    .textFieldStyle(.roundedBorder)
                    .font(AppTypography.bodyPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Model").font(AppTypography.fieldLabel)
                TextField("gpt-4o", text: $aiModel)
                    .textFieldStyle(.roundedBorder)
                    .font(AppTypography.bodyPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("API Key").font(AppTypography.fieldLabel)
                HStack {
                    SecureField("sk-...", text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)
                        .font(AppTypography.bodyPrimary)
                    Button("Save") {
                        do {
                            try keychain.saveAPIKey(apiKeyInput)
                            apiKeyInput = ""
                            keySaved = true
                            keyError = nil
                        } catch {
                            keySaved = false
                            keyError = error.localizedDescription
                        }
                    }
                    .font(AppTypography.buttonLabel)
                }
                if let keyError {
                    Text(keyError)
                        .font(AppTypography.metaLabel)
                        .foregroundColor(AppColors.danger)
                }
                if keySaved {
                    Text("API key saved to Keychain")
                        .font(AppTypography.metaLabel)
                        .foregroundColor(AppColors.success)
                }
            }

            HStack(spacing: AppSpacing.space4) {
                SecondaryButton(title: isTestingConnection ? "Testing..." : "Test Connection") {
                    testConnection()
                }
                if let result = connectionTestResult {
                    Text(result)
                        .font(AppTypography.metaLabel)
                        .foregroundColor(result.contains("OK") ? AppColors.success : AppColors.danger)
                }
            }
        }
    }

    // MARK: - App section

    private var appSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.fieldGap) {
            Text("App")
                .font(AppTypography.sectionTitle)

            Text("iPaper v1.0 — 本地 macOS 论文进度管理")
                .font(AppTypography.bodySecondary)
                .foregroundColor(AppColors.textTertiary)
        }
    }

    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil

        Task {
            do {
                try await aiService.testConnection()
                connectionTestResult = "OK"
            } catch {
                connectionTestResult = error.localizedDescription
            }
            isTestingConnection = false
        }
    }
}
