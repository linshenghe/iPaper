import SwiftUI

/// Papers main page: toolbar + secondary status + list.
struct PaperPageView: View {
    @ObservedObject var dataStore: DataStore
    @EnvironmentObject private var timerController: PaperTimerController

    let title: String
    let papers: [Paper]

    @State private var searchText = ""
    @State private var selectedFilter: PaperStatus?
    @State private var showEditor = false
    @State private var editingPaper: Paper?

    private var hasActiveTimer: Bool { papers.contains(where: \.isRunning) }

    var body: some View {
        VStack(spacing: 0) {
            AppToolbar(
                title: title,
                searchText: $searchText,
                filters: {
                    ForEach(PaperStatus.allCases, id: \.rawValue) { status in
                        FilterChip(
                            label: status.rawValue,
                            isSelected: selectedFilter == status,
                            action: {
                                selectedFilter = (selectedFilter == status) ? nil : status
                            }
                        )
                    }
                },
                actions: {
                    SecondaryButton(title: "AI Assist", action: { /* Phase 6 */ })
                    PrimaryButton(title: "+ New Paper", action: { openNew() })
                }
            )

            secondaryStatus

            PaperListView(
                dataStore: dataStore,
                searchText: $searchText,
                selectedFilter: $selectedFilter,
                papers: papers,
                onEdit: openEdit,
                onStartStop: toggleTimer
            )
        }
        .sheet(isPresented: $showEditor) {
            PaperEditorSheet(dataStore: dataStore, existingPaper: editingPaper)
        }
    }

    // MARK: - Actions

    private func openNew() {
        editingPaper = nil
        showEditor = true
    }

    private func openEdit(_ paper: Paper?) {
        guard let paper else {
            openNew()
            return
        }
        editingPaper = paper
        showEditor = true
    }

    private func toggleTimer(_ paper: Paper) {
        if paper.isRunning {
            timerController.stop(paperID: paper.id)
        } else {
            timerController.start(paperID: paper.id)
        }
        try? dataStore.save()
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
            .environmentObject(env.timerController)
            .frame(width: 800, height: 500)
        }
    }
    return PreviewWrapper()
}
