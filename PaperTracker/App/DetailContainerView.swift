import SwiftUI

/// Right-side container. Delegates to the appropriate page based on sidebar selection.
struct DetailContainerView: View {
    let selection: SidebarNavigation
    @ObservedObject var dataStore: DataStore

    var body: some View {
        Group {
            switch selection {
            case .allPapers, .writing, .submitted, .rnr, .acceptedPublished, .today:
                PaperPageView(
                    dataStore: dataStore,
                    title: selection.rawValue,
                    papers: papersForSelection
                )
            case .reviews:
                ReviewPageView(dataStore: dataStore)
            case .sessions:
                SessionPageView(dataStore: dataStore)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.windowBg)
    }

    private var papersForSelection: [Paper] {
        let papers = dataStore.appData.papers
        switch selection {
        case .allPapers: return papers
        case .today: return papers.filter(isTodayPaper)
        case .writing: return papers.filter { $0.status == .writing }
        case .submitted: return papers.filter { $0.status == .submitted }
        case .rnr: return papers.filter { $0.status == .rnr }
        case .acceptedPublished:
            return papers.filter { $0.status == .accepted || $0.status == .published }
        default: return []
        }
    }
}

private func isTodayPaper(_ paper: Paper) -> Bool {
    paper.isRunning || paper.deadline.map { Calendar.current.isDateInToday($0) } == true
}

#Preview {
    DetailContainerView(
        selection: .allPapers,
        dataStore: AppEnvironment.bootstrap().dataStore
    )
}
