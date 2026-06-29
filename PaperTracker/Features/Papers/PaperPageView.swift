import SwiftUI

/// Papers main page: toolbar + secondary status + list.
/// Holds page-level UI state (search, filter, selection).
struct PaperPageView: View {
    @ObservedObject var dataStore: DataStore
    let title: String
    let papers: [Paper]

    @State private var searchText = ""
    @State private var selectedFilter: PaperStatus?

    private var hasActiveTimer: Bool { papers.contains(where: \.isRunning) }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            AppToolbar(
                title: title,
                searchText: $searchText,
                filters: {
                    ForEach(PaperStatus.allCases, id: \.rawValue) { status in
                        FilterChip(
                            label: status.rawValue,
                            isSelected: selectedFilter == status,
                            action: {
                                if selectedFilter == status {
                                    selectedFilter = nil
                                } else {
                                    selectedFilter = status
                                }
                            }
                        )
                    }
                },
                actions: {
                    SecondaryButton(title: "AI Assist", action: { /* Phase 6 */ })
                    PrimaryButton(title: "+ New Paper", action: { /* Phase 3 */ })
                }
            )

            // Secondary status strip
            secondaryStatus

            // List
            PaperListView(
                dataStore: dataStore,
                searchText: $searchText,
                selectedFilter: $selectedFilter,
                papers: papers
            )
        }
    }

    // MARK: - Secondary status

    @ViewBuilder
    private var secondaryStatus: some View {
        let filtered = filteredPapers
        let running = papers.first(where: \.isRunning)

        if !filtered.isEmpty || running != nil {
            HStack(spacing: AppSpacing.space6) {
                Text("\(filtered.count) papers")
                    .font(AppTypography.metaLabel)
                    .foregroundColor(AppColors.textTertiary)

                if let active = running {
                    Circle()
                        .fill(AppColors.accentPrimary)
                        .frame(width: 6, height: 6)
                    Text("1 active timer")
                        .font(AppTypography.metaLabel)
                        .foregroundColor(AppColors.textSecondary)
                    Text(active.title)
                        .font(AppTypography.metaLabel)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                if selectedFilter != nil {
                    Button("Clear filter") {
                        selectedFilter = nil
                    }
                    .font(AppTypography.metaLabel)
                    .foregroundColor(AppColors.accentPrimary)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.pagePadding)
            .padding(.vertical, AppSpacing.space3)
        }
    }

    // MARK: - Helpers

    private var filteredPapers: [Paper] {
        var result = papers
        if let filter = selectedFilter {
            result = result.filter { $0.status == filter }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.journal.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var env = AppEnvironment.bootstrap()
        var body: some View {
            PaperPageView(
                dataStore: env.dataStore,
                title: "All Papers",
                papers: []
            )
            .frame(width: 800, height: 500)
        }
    }
    return PreviewWrapper()
}
