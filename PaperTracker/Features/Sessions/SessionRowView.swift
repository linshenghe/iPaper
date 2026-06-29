import SwiftUI

struct SessionRowView: View {
    let session: Session
    var onEdit: (() -> Void)?

    var body: some View {
        HStack(spacing: AppSpacing.space5) {
            Image(systemName: session.type == .paper ? "doc.text" : "eyeglasses")
                .font(.system(size: 11))
                .foregroundColor(session.type == .paper ? AppColors.accentPrimary : AppColors.statusRNR)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.targetName)
                    .font(AppTypography.bodyPrimary)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                if !session.note.isEmpty {
                    Text(session.note)
                        .font(AppTypography.bodySecondary)
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(DateFormatting.formatTimer(session.durationSeconds))
                    .font(AppTypography.timerText)
                    .foregroundColor(AppColors.textSecondary)
                Text(session.source == .timer ? "Timer" : "Manual")
                    .font(AppTypography.metaLabel)
                    .foregroundColor(AppColors.textTertiary)
            }

            Button("Edit") { onEdit?() }
                .font(AppTypography.bodyTertiary)
                .foregroundColor(AppColors.accentPrimary)
                .buttonStyle(.plain)
        }
        .padding(.vertical, AppSpacing.space4)
        .padding(.horizontal, AppSpacing.rowPaddingHorizontal)
    }
}

#Preview {
    List {
        SessionRowView(session: Session(
            id: "s1", type: .paper, targetId: "p1", targetName: "测试论文",
            startedAt: Date().addingTimeInterval(-3600), endedAt: Date(),
            durationSeconds: 3600, note: "写完了引言", source: .timer
        ))
        SessionRowView(session: Session(
            id: "s2", type: .review, targetId: "r1", targetName: "Nature审稿",
            startedAt: Date().addingTimeInterval(-1800), endedAt: Date(),
            durationSeconds: 1800, note: "", source: .manual
        ))
    }
    .listStyle(.plain)
    .padding()
}
