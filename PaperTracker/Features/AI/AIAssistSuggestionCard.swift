import SwiftUI

/// Single suggested field with apply action.
struct AIAssistSuggestionCard: View {
    let label: String
    let value: String
    let confidence: Double
    var isApplied: Bool
    var onApply: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.space5) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AppTypography.fieldLabel)
                    .foregroundColor(AppColors.textSecondary)
                Text(value.isEmpty ? "(empty)" : value)
                    .font(AppTypography.bodyPrimary)
                    .foregroundColor(value.isEmpty ? AppColors.textTertiary : AppColors.textPrimary)
                    .lineLimit(2)
            }

            Spacer()

            // Confidence badge
            Text("\(Int(confidence * 100))%")
                .font(AppTypography.metaLabel)
                .foregroundColor(confidenceColor)
                .padding(.horizontal, AppSpacing.space3)
                .padding(.vertical, 2)
                .background(confidenceColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.chip))

            Button(isApplied ? "Applied" : "Apply") {
                onApply()
            }
            .font(AppTypography.bodyTertiary)
            .foregroundColor(isApplied ? AppColors.textTertiary : AppColors.accentPrimary)
            .disabled(isApplied)
        }
        .padding(AppSpacing.space6)
        .background(AppColors.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.control)
                .stroke(isApplied ? AppColors.success : AppColors.lineSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.control))
    }

    private var confidenceColor: Color {
        if confidence >= 0.8 { return AppColors.success }
        if confidence >= 0.5 { return AppColors.warning }
        return AppColors.danger
    }
}

#Preview {
    VStack {
        AIAssistSuggestionCard(
            label: "Title",
            value: "中国引文偏见研究",
            confidence: 0.9,
            isApplied: false,
            onApply: {}
        )
        AIAssistSuggestionCard(
            label: "Journal",
            value: "",
            confidence: 0.2,
            isApplied: true,
            onApply: {}
        )
    }
    .padding()
}
