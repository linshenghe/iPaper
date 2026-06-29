import SwiftUI

struct ReviewPageView: View {
    @ObservedObject var dataStore: DataStore
    @State private var searchText = ""
    @State private var selectedFilter: ReviewStatus?
    @State private var showEditor = false
    @State private var editingReview: Review?

    var body: some View {
        VStack(spacing: 0) {
            AppToolbar(
                title: "Reviews",
                searchText: $searchText,
                filters: {
                    FilterChip(label: "In Progress", isSelected: selectedFilter == .inProgress) {
                        selectedFilter = (selectedFilter == .inProgress) ? nil : .inProgress
                    }
                    FilterChip(label: "Completed", isSelected: selectedFilter == .completed) {
                        selectedFilter = (selectedFilter == .completed) ? nil : .completed
                    }
                },
                actions: {
                    PrimaryButton(title: "+ New Review") {
                        editingReview = nil
                        showEditor = true
                    }
                }
            )

            ReviewListView(
                dataStore: dataStore,
                searchText: $searchText,
                selectedFilter: $selectedFilter,
                onEdit: { review in
                    editingReview = review
                    showEditor = true
                },
                reviews: dataStore.appData.reviews
            )
        }
        .sheet(isPresented: $showEditor) {
            ReviewEditorSheet(dataStore: dataStore, existingReview: editingReview)
        }
    }
}

#Preview {
    ReviewPageView(dataStore: AppEnvironment.bootstrap().dataStore)
        .frame(width: 700, height: 400)
}
