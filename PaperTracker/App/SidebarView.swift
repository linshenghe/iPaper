import SwiftUI

enum SidebarNavigation: String, CaseIterable {
    case allPapers = "All Papers"
    case writing = "Writing"
    case submitted = "Submitted"
    case rnr = "R&R"
    case acceptedPublished = "Accepted / Published"
    case reviews = "Reviews"
    case sessions = "Sessions"
    case today = "Today"

    var icon: String {
        switch self {
        case .allPapers: return "doc.text"
        case .writing: return "pencil"
        case .submitted: return "paperplane"
        case .rnr: return "arrow.triangle.2.circlepath"
        case .acceptedPublished: return "checkmark.seal"
        case .reviews: return "eyeglasses"
        case .sessions: return "clock"
        case .today: return "sun.max"
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarNavigation
    @ObservedObject var dataStore: DataStore
    var onSettings: (() -> Void)?
    private let keychain = KeychainService()

    // pony-tail: counts computed inline; could be cached if data grows large
    private func count(for nav: SidebarNavigation) -> Int {
        switch nav {
        case .allPapers: return dataStore.appData.papers.count
        case .writing: return dataStore.appData.papers.filter { $0.status == .writing }.count
        case .submitted: return dataStore.appData.papers.filter { $0.status == .submitted }.count
        case .rnr: return dataStore.appData.papers.filter { $0.status == .rnr }.count
        case .acceptedPublished:
            return dataStore.appData.papers.filter { $0.status == .accepted || $0.status == .published }.count
        case .reviews: return dataStore.appData.reviews.count
        case .sessions: return dataStore.appData.sessions.count
        case .today: return dataStore.appData.papers.filter(isTodayPaper).count
        }
    }

    private var hasStoredAPIKey: Bool {
        guard let key = try? keychain.loadAPIKey() else { return false }
        return !key.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // App identity
            HStack {
                Text("iPaper")
                    .font(AppTypography.windowTitle)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.sidebarPadding)
            .padding(.vertical, AppSpacing.space6)

            // Navigation
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(SidebarNavigation.allCases, id: \.rawValue) { item in
                        SidebarRow(
                            icon: item.icon,
                            title: item.rawValue,
                            count: count(for: item),
                            isSelected: selection == item,
                            action: { selection = item }
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.space4)
            }

            // Bottom status
            SidebarStatus(
                lastSavedAt: dataStore.appData.settings.lastSavedAt,
                hasActiveTimer: dataStore.appData.papers.contains(where: \.isRunning),
                aiConnected: hasStoredAPIKey,
                onSettings: onSettings
            )
        }
        .background(AppColors.sidebarBg)
        .frame(minWidth: 200, idealWidth: 220)
    }
}

private func isTodayPaper(_ paper: Paper) -> Bool {
    paper.isRunning || paper.deadline.map { Calendar.current.isDateInToday($0) } == true
}

// MARK: - Sidebar Row

private struct SidebarRow: View {
    let icon: String
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.space3) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .frame(width: 18, alignment: .leading)
                Text(title)
                    .font(AppTypography.bodyPrimary)
                Spacer()
                if count > 0 {
                    Text("\(count)")
                        .font(AppTypography.metaLabel)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .foregroundColor(isSelected ? AppColors.accentPrimary : AppColors.textSecondary)
            .frame(height: AppMetrics.sidebarRowHeight)
            .padding(.horizontal, AppSpacing.space5)
            .background(
                isSelected
                    ? AppColors.accentSoft
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.selectionCapsule))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bottom Status

private struct SidebarStatus: View {
    let lastSavedAt: Date?
    let hasActiveTimer: Bool
    let aiConnected: Bool
    var onSettings: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.space2) {
            Divider()
                .foregroundColor(AppColors.lineSubtle)
            HStack {
                Image(systemName: "circle.fill")
                    .font(.system(size: 5))
                    .foregroundColor(AppColors.success)
                Text(lastSavedAt.map { "Saved \(DateFormatting.displayFormatter.string(from: $0))" } ?? "Ready")
                    .font(AppTypography.metaLabel)
                    .foregroundColor(AppColors.textTertiary)
            }
            if hasActiveTimer {
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundColor(AppColors.accentPrimary)
                    Text("Timer running")
                        .font(AppTypography.metaLabel)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            HStack {
                Image(systemName: "circle.fill")
                    .font(.system(size: 5))
                    .foregroundColor(aiConnected ? AppColors.success : AppColors.textTertiary)
                Text(aiConnected ? "AI connected" : "AI not configured")
                    .font(AppTypography.metaLabel)
                    .foregroundColor(AppColors.textTertiary)
            }
            Button(action: { onSettings?() }) {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 9))
                    Text("Settings")
                        .font(AppTypography.metaLabel)
                }
                .foregroundColor(AppColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.sidebarPadding)
        .padding(.vertical, AppSpacing.space5)
    }
}

#Preview {
    @Previewable @State var selection: SidebarNavigation = .allPapers
    return SidebarView(
        selection: $selection,
        dataStore: AppEnvironment.bootstrap().dataStore
    )
}
