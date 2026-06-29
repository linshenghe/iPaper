import SwiftUI

/// Status tag: small dot + text. Papers and Reviews share this.
struct StatusTag: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: AppMetrics.statusDotTextGap) {
            Circle()
                .fill(color)
                .frame(width: AppMetrics.statusDotDiameter, height: AppMetrics.statusDotDiameter)
            Text(text)
                .font(AppTypography.chipLabel)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - Convenience initializers

extension StatusTag {
    init(paperStatus: PaperStatus) {
        self.init(
            text: paperStatus.rawValue,
            color: AppColors.statusColor(for: paperStatus)
        )
    }

    init(reviewStatus: ReviewStatus) {
        self.init(
            text: reviewStatus == .completed ? "Completed" : "In Progress",
            color: AppColors.statusColor(for: reviewStatus)
        )
    }
}

#Preview {
    VStack(spacing: 8) {
        StatusTag(paperStatus: .writing)
        StatusTag(paperStatus: .submitted)
        StatusTag(reviewStatus: .inProgress)
    }
    .padding()
}
