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
                PlaceholderView(title: "Reviews")
            case .sessions:
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
        case .acceptedPublished:
            return papers.filter { $0.status == .accepted || $0.status == .published }
        default: return []
        }
    }
}

// MARK: - Generic placeholder for unimplemented pages

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
