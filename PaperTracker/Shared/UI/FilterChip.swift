import SwiftUI

struct FilterChip: View {
    let label: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppTypography.chipLabel)
                .foregroundColor(isSelected ? AppColors.accentPrimary : AppColors.textSecondary)
                .frame(height: AppMetrics.controlHeightCompact)
                .padding(.horizontal, AppSpacing.space5)
                .background(isSelected ? AppColors.accentSoft : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.filterChipCorner))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.filterChipCorner)
                        .stroke(isSelected ? AppColors.accentSoft : AppColors.lineSubtle, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        FilterChip(label: "Writing", isSelected: true, action: {})
        FilterChip(label: "Submitted", isSelected: false, action: {})
    }
    .padding()
}
