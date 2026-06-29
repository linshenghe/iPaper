import SwiftUI

struct SecondaryButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.buttonLabel)
                .foregroundColor(AppColors.accentPrimary)
                .frame(height: AppMetrics.controlHeightStandard)
                .padding(.horizontal, AppSpacing.space8)
                .background(AppColors.surfacePrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.buttonCorner)
                        .stroke(AppColors.accentSoft, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.buttonCorner))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SecondaryButton(title: "AI Assist", action: {})
        .padding()
}
