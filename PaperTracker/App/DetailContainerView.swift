import SwiftUI

/// Right-side container. Delegates to the appropriate page based on sidebar selection.
struct DetailContainerView: View {
    let selection: SidebarNavigation
    @ObservedObject var dataStore: DataStore

    var body: some View {
        Group {
            switch selection {
            case .allPapers, .writing, .submitted, .rnr, .acceptedPublished, .today:
                // ponytail: placeholder until Phase 2 (Papers page)
                PapersPlaceholderView(
                    title: selection.rawValue,
                    papers: papersForSelection
                )
            case .reviews:
                // ponytail: placeholder until Phase 4
                PlaceholderView(title: "Reviews")
            case .sessions:
                // ponytail: placeholder until Phase 4
                PlaceholderView(title: "Sessions")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.windowBg)
    }

    private var papersForSelection: [Paper] {
        let papers = dataStore.appData.papers
        switch selection {
        case .allPapers, .today: return papers
        case .writing: return papers.filter { $0.status == .writing }
        case .submitted: return papers.filter { $0.status == .submitted }
        case .rnr: return papers.filter { $0.status == .rnr }
        case .acceptedPublished: return papers.filter { $0.status == .accepted || $0.status == .published }
        default: return []
        }
    }
}

// MARK: - Papers placeholder

private struct PapersPlaceholderView: View {
    let title: String
    let papers: [Paper]
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            AppToolbar(
                title: title,
                searchText: $searchText,
                filters: {
                    ForEach(PaperStatus.allCases, id: \.rawValue) { status in
                        FilterChip(
                            label: status.rawValue,
                            isSelected: false,
                            action: {}
                        )
                    }
                },
                actions: {
                    SecondaryButton(title: "AI Assist", action: {})
                    PrimaryButton(title: "+ New Paper", action: {})
                }
            )

            if papers.isEmpty {
                EmptyStateView(
                    title: "Start with your first paper",
                    subtitle: "这里是论文管理器，追踪你的研究写作进度。",
                    buttonTitle: "New Paper",
                    buttonAction: {}
                )
            } else {
                List(papers) { paper in
                    HStack {
                        StatusTag(paperStatus: paper.status)
                        VStack(alignment: .leading) {
                            Text(paper.title)
                                .font(AppTypography.bodyPrimary)
                                .foregroundColor(AppColors.textPrimary)
                            Text(paper.journal)
                                .font(AppTypography.bodySecondary)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        Spacer()
                        Text("\(paper.totalSeconds / 60)m")
                            .font(AppTypography.timerText)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.vertical, AppSpacing.space3)
                }
            }
        }
    }
}

// MARK: - Generic placeholder

private struct PlaceholderView: View {
    let title: String

    var body: some View {
        VStack {
            Text(title)
                .font(AppTypography.pageTitle)
            Text("Coming in Phase 4")
                .font(AppTypography.bodySecondary)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DetailContainerView(
        selection: .allPapers,
        dataStore: AppEnvironment.bootstrap().dataStore
    )
}
