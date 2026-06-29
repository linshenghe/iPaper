import SwiftUI

/// Paper list: renders rows, handles empty/search/filter states, selection.
struct PaperListView: View {
    @ObservedObject var dataStore: DataStore
    @Binding var searchText: String
    @Binding var selectedFilter: PaperStatus?

    let papers: [Paper]

    // MARK: - Filtered data

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

    private var isEmpty: Bool { papers.isEmpty }
    private var isSearchEmpty: Bool { !papers.isEmpty && !searchText.isEmpty && filteredPapers.isEmpty }
    private var isFilterEmpty: Bool {
        !papers.isEmpty && selectedFilter != nil && filteredPapers.isEmpty && searchText.isEmpty
    }

    var body: some View {
        if isEmpty {
            EmptyStateView(
                title: "Start with your first paper",
                subtitle: "这里是论文管理器，追踪你的研究写作进度。",
                buttonTitle: "New Paper",
                buttonAction: { /* ponytail: wired in Phase 3 */ }
            )
        } else if isSearchEmpty {
            EmptyStateView(
                title: "没有匹配的论文",
                subtitle: "尝试其他关键词。",
                buttonTitle: "清空搜索",
                buttonAction: { searchText = "" }
            )
        } else if isFilterEmpty {
            EmptyStateView(
                title: "当前筛选没有结果",
                subtitle: "尝试不同的筛选条件。",
                buttonTitle: "清除筛选",
                buttonAction: { selectedFilter = nil }
            )
        } else {
            List(filteredPapers) { paper in
                PaperRowView(paper: paper)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .contentShape(Rectangle())
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview {
    @Previewable @State var searchText = ""
    @Previewable @State var filter: PaperStatus?
    let env = AppEnvironment.bootstrap()

    return PaperListView(
        dataStore: env.dataStore,
        searchText: $searchText,
        selectedFilter: $filter,
        papers: [
            Paper(
                id: "p1", title: "中国引文偏见", status: .writing,
                journal: "CPJ", deadline: nil, totalSeconds: 120,
                isRunning: true, sessionStart: Date(),
                createdAt: Date(), updatedAt: Date(), note: ""
            )
        ]
    )
}
