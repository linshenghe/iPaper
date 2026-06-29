import SwiftUI

/// Sessions grouped by date in reverse chronological order — a timeline, not a table.
struct SessionTimelineView: View {
    let sessions: [Session]
    var onEdit: ((Session) -> Void)?
    var onDelete: ((Session) -> Void)?

    private var groupedByDate: [(date: Date, sessions: [Session])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session -> Date in
            calendar.startOfDay(for: session.startedAt)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, sessions: $0.value.sorted { $0.startedAt > $1.startedAt }) }
    }

    var body: some View {
        if sessions.isEmpty {
            EmptyStateView(
                title: "No sessions yet",
                subtitle: "开始计时或手动添加日志后，这里会出现记录。"
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(groupedByDate, id: \.date) { group in
                        // Date header
                        Text(groupTitle(for: group.date))
                            .font(AppTypography.sectionTitle)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, AppSpacing.rowPaddingHorizontal)
                            .padding(.top, AppSpacing.space8)
                            .padding(.bottom, AppSpacing.space3)

                        ForEach(group.sessions) { session in
                            SessionRowView(session: session, onEdit: { onEdit?(session) })
                            Divider()
                                .padding(.horizontal, AppSpacing.rowPaddingHorizontal)
                                .foregroundColor(AppColors.lineSubtle)
                        }
                    }
                }
            }
        }
    }

    private func groupTitle(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return DateFormatting.displayFormatter.string(from: date)
    }
}

#Preview {
    SessionTimelineView(sessions: [])
        .frame(width: 600, height: 300)
}
