import SwiftUI

/// Lightweight global status strip. Shows active timer info when a paper is running.
struct TopStatusStripView: View {
    @ObservedObject var dataStore: DataStore

    private var runningPaper: Paper? {
        dataStore.appData.papers.first(where: \.isRunning)
    }

    var body: some View {
        if let paper = runningPaper {
            HStack(spacing: AppSpacing.space4) {
                Circle()
                    .fill(AppColors.accentPrimary)
                    .frame(width: 6, height: 6)
                Text("Writing now")
                    .font(AppTypography.metaLabel)
                    .foregroundColor(AppColors.textSecondary)
                Text(paper.title)
                    .font(AppTypography.metaLabel)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                Spacer()
                Text(formatSeconds(paper.totalSeconds))
                    .font(AppTypography.timerText)
                    .foregroundColor(AppColors.accentPrimary)
            }
            .padding(.horizontal, AppSpacing.pagePadding)
            .padding(.vertical, AppSpacing.space3)
            .background(AppColors.surfaceTertiary)
        }
    }

    private func formatSeconds(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    @Previewable @StateObject var env = AppEnvironment.bootstrap()
    return TopStatusStripView(dataStore: env.dataStore)
}
