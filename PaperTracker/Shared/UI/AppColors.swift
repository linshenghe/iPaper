import SwiftUI

/// Single-source color definitions. First version: light theme only.
enum AppColors {
    // MARK: - Backgrounds
    static let windowBg = Color(hex: "#F3F4F6")
    static let sidebarBg = Color(hex: "#ECEFF3")
    static let surfacePrimary = Color(hex: "#FFFFFF")
    static let surfaceSecondary = Color(hex: "#F7F8FA")
    static let surfaceTertiary = Color(hex: "#EEF1F5")

    // MARK: - Text
    static let textPrimary = Color(hex: "#1E2430")
    static let textSecondary = Color(hex: "#667085")
    static let textTertiary = Color(hex: "#8A94A6")
    static let textOnAccent = Color(hex: "#FFFFFF")

    // MARK: - Lines
    static let lineSubtle = Color(hex: "#E3E7EE")
    static let lineStandard = Color(hex: "#D9DEE6")
    static let lineStrong = Color(hex: "#C8D0DB")

    // MARK: - Accent
    static let accentPrimary = Color(hex: "#315AA9")
    static let accentPressed = Color(hex: "#274987")
    static let accentSoft = Color(hex: "#E7EEF9")
    static let accentTint = Color(hex: "#315AA9").opacity(0.10)

    // MARK: - Status
    static let statusWriting = Color(hex: "#9C7A2B")
    static let statusSubmitted = Color(hex: "#4E708F")
    static let statusRNR = Color(hex: "#75618A")
    static let statusAccepted = Color(hex: "#46745B")
    static let statusPublished = Color(hex: "#4B7C78")

    // MARK: - Feedback
    static let success = Color(hex: "#3F7A5A")
    static let warning = Color(hex: "#B4882E")
    static let danger = Color(hex: "#B24A45")
    static let dangerSoft = Color(hex: "#FBE9E7")

    // MARK: - Semantic
    static func statusColor(for status: PaperStatus) -> Color {
        switch status {
        case .writing: return statusWriting
        case .submitted: return statusSubmitted
        case .rnr: return statusRNR
        case .accepted: return statusAccepted
        case .published: return statusPublished
        }
    }

    static func statusColor(for status: ReviewStatus) -> Color {
        switch status {
        case .inProgress: return statusWriting
        case .completed: return statusAccepted
        }
    }
}

// MARK: - Hex init

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
