import SwiftUI

struct ReviewRowView: View {
    let review: Review
    var onEdit: (() -> Void)?

    var body: some View {
        HStack(spacing: AppSpacing.space5) {
            VStack(alignment: .leading, spacing: AppSpacing.space2) {
                Text(review.journal)
                    .font(AppTypography.bodyPrimary)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                if !review.note.isEmpty {
                    Text(review.note)
                        .font(AppTypography.bodySecondary)
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
            StatusTag(reviewStatus: review.status)
            if let deadline = review.deadline {
                let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
                Text(DateFormatting.deadlineLabel(review.deadline))
                    .font(AppTypography.numericMeta)
                    .foregroundColor(days < 0 ? AppColors.danger : (days <= 3 ? AppColors.warning : AppColors.textTertiary))
            }
            Menu {
                Button("Edit") { onEdit?() }
                Divider()
                Button("Delete", role: .destructive) {}
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textTertiary)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
        .padding(.vertical, AppSpacing.rowPaddingVertical)
        .padding(.horizontal, AppSpacing.rowPaddingHorizontal)
    }
}

#Preview {
    List {
        ReviewRowView(review: Review(
            id: "r1", journal: "Nature", deadline: Date(),
            status: .inProgress, note: "审稿中",
            createdAt: Date(), updatedAt: Date()
        ))
    }
    .listStyle(.plain)
    .padding()
}
