import SwiftUI

struct SessionPageView: View {
    @ObservedObject var dataStore: DataStore
    @State private var selectedFilter: SessionFilter = .all
    @State private var editingSession: Session?

    enum SessionFilter: String, CaseIterable {
        case all = "All"
        case papers = "Papers"
        case reviews = "Reviews"
        case today = "Today"
        case thisWeek = "This Week"
    }

    private var filtered: [Session] {
        let sessions = dataStore.appData.sessions
        switch selectedFilter {
        case .all: return sessions
        case .papers: return sessions.filter { $0.type == .paper }
        case .reviews: return sessions.filter { $0.type == .review }
        case .today: return sessions.filter { Calendar.current.isDateInToday($0.startedAt) }
        case .thisWeek:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return sessions.filter { $0.startedAt >= weekAgo }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar with filter chips
            HStack(spacing: AppMetrics.toolbarInnerGap) {
                Text("Sessions")
                    .font(AppTypography.pageTitle)

                ForEach(SessionFilter.allCases, id: \.rawValue) { filter in
                    FilterChip(
                        label: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        action: { selectedFilter = filter }
                    )
                }
            }
            .frame(height: AppMetrics.toolbarHeight)
            .padding(.horizontal, AppSpacing.pagePadding)

            SessionTimelineView(
                sessions: filtered,
                onEdit: { editingSession = $0 }
            )
        }
        .sheet(item: $editingSession) { session in
            SessionEditorSheet(dataStore: dataStore, session: session)
        }
    }
}

#Preview {
    SessionPageView(dataStore: AppEnvironment.bootstrap().dataStore)
        .frame(width: 700, height: 400)
}
