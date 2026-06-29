import SwiftUI

struct SearchField: View {
    @Binding var text: String
    var placeholder: String = "搜索..."

    var body: some View {
        HStack(spacing: AppSpacing.space3) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textTertiary)
                .font(.system(size: 12))
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(AppTypography.bodySecondary)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textTertiary)
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.space4)
        .frame(minWidth: 120, idealWidth: AppMetrics.toolbarSearchWidth, maxHeight: AppMetrics.controlHeightStandard)
        .background(AppColors.surfaceSecondary)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.searchFieldCorner)
                .stroke(AppColors.lineSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.searchFieldCorner))
    }
}

#Preview {
    @Previewable @State var text = ""
    return SearchField(text: $text).padding()
}
