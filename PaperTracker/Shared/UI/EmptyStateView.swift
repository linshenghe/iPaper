import SwiftUI

/// Shared empty state for Papers, Reviews, Sessions, search-no-results.
struct EmptyStateView: View {
    let title: String
    let subtitle: String
    var buttonTitle: String?
    var buttonAction: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.space6) {
            Text(title)
                .font(AppTypography.sectionTitle)
                .foregroundColor(AppColors.textPrimary)
            Text(subtitle)
                .font(AppTypography.bodySecondary)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
            if let buttonTitle, let buttonAction {
                PrimaryButton(title: LocalizedStringKey(buttonTitle), action: buttonAction)
                    .padding(.top, AppSpacing.space4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.pagePadding)
    }
}

#Preview {
    EmptyStateView(
        title: "Start with your first paper",
        subtitle: "这里是论文管理器，追踪你的研究写作进度。",
        buttonTitle: "New Paper",
        buttonAction: {}
    )
}
