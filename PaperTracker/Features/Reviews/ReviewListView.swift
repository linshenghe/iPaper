import SwiftUI

struct ReviewListView: View {
    @ObservedObject var dataStore: DataStore
    @Binding var searchText: String
    @Binding var selectedFilter: ReviewStatus?
    var onEdit: ((Review?) -> Void)?

    let reviews: [Review]

    private var filtered: [Review] {
        var result = reviews
        if let filter = selectedFilter {
            result = result.filter { $0.status == filter }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.journal.localizedCaseInsensitiveContains(searchText) ||
                $0.note.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        if reviews.isEmpty {
            EmptyStateView(
                title: "No reviews yet",
                subtitle: "这里记录审稿任务。",
                buttonTitle: "New Review",
                buttonAction: { onEdit?(nil) }
            )
        } else if !searchText.isEmpty && filtered.isEmpty {
            EmptyStateView(
                title: "没有匹配的审稿",
                subtitle: "尝试其他关键词。",
                buttonTitle: "清空搜索",
                buttonAction: { searchText = "" }
            )
        } else if selectedFilter != nil && filtered.isEmpty && searchText.isEmpty {
            EmptyStateView(
                title: "当前筛选没有结果",
                subtitle: "尝试不同的筛选条件。",
                buttonTitle: "清除筛选",
                buttonAction: { selectedFilter = nil }
            )
        } else {
            List(filtered) { review in
                ReviewRowView(review: review, onEdit: { onEdit?(review) })
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .contentShape(Rectangle())
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
}
