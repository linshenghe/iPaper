import SwiftUI

/// Central typography definitions. macOS system fonts only.
enum AppTypography {
    // MARK: - Title levels
    static let windowTitle = Font.system(.title, design: .default).weight(.semibold)
    static let pageTitle = Font.system(.title2, design: .default).weight(.semibold)
    static let sectionTitle = Font.system(.subheadline, design: .default).weight(.semibold)

    // MARK: - Body
    static let bodyPrimary = Font.system(.subheadline, design: .default)
    static let bodySecondary = Font.system(.caption, design: .default)
    static let bodyTertiary = Font.system(.caption2, design: .default)

    // MARK: - UI elements
    static let buttonLabel = Font.system(.subheadline, design: .default).weight(.semibold)
    static let chipLabel = Font.system(.caption, design: .default).weight(.medium)
    static let fieldLabel = Font.system(.caption2, design: .default).weight(.medium)
    static let metaLabel = Font.system(.caption2, design: .default)

    // MARK: - Monospace
    static let timerText = Font.system(.subheadline, design: .monospaced).weight(.medium)
    static let numericMeta = Font.system(.caption2, design: .monospaced)
}
