import SwiftUI

/// Shared toolbar used across Papers / Reviews / Sessions pages.
struct AppToolbar<Actions: View, Filters: View>: View {
    let title: String
    @Binding var searchText: String
    @ViewBuilder let filters: () -> Filters
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        HStack(spacing: AppMetrics.toolbarInnerGap) {
            // Title
            Text(title)
                .font(AppTypography.pageTitle)
                .foregroundColor(AppColors.textPrimary)

            // Search
            SearchField(text: $searchText)

            // Filters
            filters()

            Spacer()

            // Actions
            actions()
        }
        .frame(height: AppMetrics.toolbarHeight)
        .padding(.horizontal, AppSpacing.pagePadding)
    }
}

// MARK: - Convenience with primary/secondary actions

extension AppToolbar where Filters == EmptyView {
    init(
        title: String,
        searchText: Binding<String>,
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.title = title
        self._searchText = searchText
        self.filters = { EmptyView() }
        self.actions = actions
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var searchText = ""
        var body: some View {
            VStack {
                AppToolbar(
                    title: "Papers",
                    searchText: $searchText,
                    filters: {
                        FilterChip(label: "Writing", isSelected: true, action: {})
                        FilterChip(label: "Submitted", isSelected: false, action: {})
                    },
                    actions: {
                        SecondaryButton(title: "AI Assist", action: {})
                        PrimaryButton(title: "+ New Paper", action: {})
                    }
                )
            }
            .padding()
            .background(AppColors.windowBg)
        }
    }
    return PreviewWrapper()
}
