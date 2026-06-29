import SwiftUI

struct PrimaryButton: View {
    let title: LocalizedStringKey
    let action: () -> Void
    var isEnabled: Bool = true

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.buttonLabel)
                .foregroundColor(AppColors.textOnAccent)
                .frame(height: AppMetrics.controlHeightStandard)
                .padding(.horizontal, AppSpacing.space8)
                .background(isEnabled ? AppColors.accentPrimary : AppColors.lineStandard)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.buttonCorner))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    HStack {
        PrimaryButton(title: "Save", action: {})
        PrimaryButton(title: "New Paper", action: {}, isEnabled: false)
    }
    .padding()
}
