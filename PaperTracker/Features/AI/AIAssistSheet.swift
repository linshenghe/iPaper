import SwiftUI

/// Structured AI assistant — input raw text, get field suggestions, apply to form.
struct AIAssistSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onApplyFields: (AISuggestion) -> Void

    @State private var inputText = ""
    @State private var state: AIState = .idle
    @State private var suggestion: AISuggestion?
    @State private var errorMessage: String?
    @State private var appliedFields: Set<String> = []

    private let aiService = AIService()

    enum AIState {
        case idle, generating, success, failure
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AI Assist")
                    .font(AppTypography.windowTitle)
                Spacer()
                Button("Close") { dismiss() }
                    .font(AppTypography.buttonLabel)
                    .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, AppSpacing.sheetPadding)
            .padding(.vertical, AppSpacing.space8)

            // Input
            VStack(alignment: .leading, spacing: AppSpacing.space3) {
                Text("Paste abstract, email, or notes — AI will extract structured fields.")
                    .font(AppTypography.bodySecondary)
                    .foregroundColor(AppColors.textTertiary)

                TextEditor(text: $inputText)
                    .font(AppTypography.bodyPrimary)
                    .frame(minHeight: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.control)
                            .stroke(AppColors.lineSubtle, lineWidth: 1)
                    )
                    .disabled(state == .generating)

                HStack {
                    PrimaryButton(
                        title: state == .generating ? "Generating..." : "Generate Suggestions",
                        action: generate,
                        isEnabled: state != .generating && !inputText.trimmingCharacters(in: .whitespaces).isEmpty
                    )
                    if state == .failure {
                        Button("Retry") { generate() }
                            .font(AppTypography.buttonLabel)
                            .foregroundColor(AppColors.accentPrimary)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.sheetPadding)
            .padding(.bottom, AppSpacing.space8)

            if let error = errorMessage {
                Text(error)
                    .font(AppTypography.metaLabel)
                    .foregroundColor(AppColors.danger)
                    .padding(.horizontal, AppSpacing.sheetPadding)
            }

            // Results
            if let suggestion, state == .success {
                ScrollView {
                    VStack(spacing: AppSpacing.space4) {
                        AIAssistSuggestionCard(
                            label: "Title",
                            value: suggestion.title,
                            confidence: max(0, suggestion.confidence),
                            isApplied: appliedFields.contains("title"),
                            onApply: { apply("title", \.title) }
                        )
                        AIAssistSuggestionCard(
                            label: "Journal",
                            value: suggestion.journal,
                            confidence: max(0, suggestion.confidence),
                            isApplied: appliedFields.contains("journal"),
                            onApply: { apply("journal", \.journal) }
                        )
                        AIAssistSuggestionCard(
                            label: "Status",
                            value: suggestion.status,
                            confidence: max(0, suggestion.status.isEmpty ? 0 : suggestion.confidence),
                            isApplied: appliedFields.contains("status"),
                            onApply: { apply("status", \.status) }
                        )
                        AIAssistSuggestionCard(
                            label: "Deadline",
                            value: suggestion.deadline,
                            confidence: max(0, suggestion.deadline.isEmpty ? 0 : suggestion.confidence),
                            isApplied: appliedFields.contains("deadline"),
                            onApply: { apply("deadline", \.deadline) }
                        )
                        AIAssistSuggestionCard(
                            label: "Note",
                            value: suggestion.note,
                            confidence: max(0, suggestion.note.isEmpty ? 0 : suggestion.confidence),
                            isApplied: appliedFields.contains("note"),
                            onApply: { apply("note", \.note) }
                        )
                    }
                    .padding(.horizontal, AppSpacing.sheetPadding)
                }

                // Footer
                HStack {
                    Spacer()
                    PrimaryButton(title: "Apply Selected & Close") {
                        onApplyFields(suggestion)
                        dismiss()
                    }
                }
                .padding(.horizontal, AppSpacing.sheetPadding)
                .padding(.vertical, AppSpacing.space8)
            }

            if state == .idle {
                Spacer()
            }
        }
        .frame(minWidth: 480, idealWidth: 520, minHeight: 500)
    }

    // MARK: - Actions

    private func generate() {
        state = .generating
        errorMessage = nil
        suggestion = nil
        appliedFields = []

        Task {
            do {
                let result = try await aiService.extractPaperInfo(from: inputText)
                suggestion = result
                state = .success
            } catch {
                errorMessage = error.localizedDescription
                state = .failure
            }
        }
    }

    private func apply(_ field: String, _ keyPath: WritableKeyPath<AISuggestion, String>) {
        appliedFields.insert(field)
        guard var s = suggestion else { return }
        // ponytail: just track which fields were selected; actual application
        // happens in onApplyFields via the parent form
        s[keyPath: keyPath] = s[keyPath: keyPath]
        // No-op here — the parent receives the full suggestion in onApplyFields
    }
}
