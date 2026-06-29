import SwiftUI

/// Single paper row — the core visual unit of the list.
struct PaperRowView: View {
    let paper: Paper
    var isRunning: Bool { paper.isRunning }

    var body: some View {
        HStack(spacing: AppSpacing.space5) {
            // Running accent bar
            if isRunning {
                Rectangle()
                    .fill(AppColors.accentPrimary)
                    .frame(width: 3)
            }

            // Left: title + journal
            VStack(alignment: .leading, spacing: AppSpacing.space2) {
                Text(paper.title)
                    .font(AppTypography.bodyPrimary)
                    .fontWeight(isRunning ? .semibold : .regular)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                if !paper.journal.isEmpty {
                    Text(paper.journal)
                        .font(AppTypography.bodySecondary)
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Center: status + deadline
            VStack(alignment: .trailing, spacing: AppSpacing.space2) {
                StatusTag(paperStatus: paper.status)

                if let deadline = paper.deadline {
                    let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
                    HStack(spacing: 4) {
                        Image(systemName: days <= 0 ? "exclamationmark.triangle.fill" : "calendar")
                            .font(.system(size: 9))
                        Text(DateFormatting.deadlineLabel(paper.deadline))
                            .font(AppTypography.numericMeta)
                    }
                    .foregroundColor(deadlineColor(days))
                }
            }

            // Right: timer + actions
            VStack(alignment: .trailing, spacing: AppSpacing.space2) {
                Text(DateFormatting.formatTimer(paper.totalSeconds))
                    .font(AppTypography.timerText)
                    .foregroundColor(isRunning ? AppColors.accentPrimary : AppColors.textSecondary)

                HStack(spacing: AppSpacing.space3) {
                    Button(isRunning ? "Stop" : "Start") {
                        // ponytail: wired in Phase 3
                    }
                    .font(AppTypography.bodyTertiary)
                    .foregroundColor(isRunning ? AppColors.danger : AppColors.accentPrimary)
                    .frame(width: 42, height: AppMetrics.controlHeightCompact)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.filterChipCorner)
                            .fill(isRunning ? AppColors.dangerSoft : AppColors.accentSoft)
                    )

                    Menu {
                        Button("Edit") {}
                        Button("Quick Note") {}
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
            }
        }
        .padding(.vertical, AppSpacing.rowPaddingVertical)
        .padding(.horizontal, AppSpacing.rowPaddingHorizontal)
        .frame(minHeight: AppMetrics.paperRowMinHeight)
        .background(rowBackground)
    }

    // MARK: - Helpers

    private var rowBackground: some View {
        Group {
            if isRunning {
                AppColors.accentTint
            } else {
                Color.clear
            }
        }
    }

    private func deadlineColor(_ days: Int) -> Color {
        if days < 0 { return AppColors.danger }
        if days <= 3 { return AppColors.warning }
        return AppColors.textTertiary
    }
}

// MARK: - Hover highlight support (ponytail: via .listRowBackground in Phase 3)

#Preview {
    let paper = Paper(
        id: "preview",
        title: "中国引文偏见研究",
        status: .writing,
        journal: "China Policy Journal",
        deadline: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
        totalSeconds: 3661,
        isRunning: true,
        sessionStart: Date(),
        createdAt: Date(),
        updatedAt: Date(),
        note: ""
    )

    return List {
        PaperRowView(paper: paper)
        PaperRowView(paper: Paper(
            id: "p2",
            title: "已完成论文",
            status: .accepted,
            journal: "Nature",
            deadline: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            totalSeconds: 7200,
            isRunning: false,
            sessionStart: nil,
            createdAt: Date(),
            updatedAt: Date(),
            note: ""
        ))
    }
    .listStyle(.plain)
    .padding()
}
