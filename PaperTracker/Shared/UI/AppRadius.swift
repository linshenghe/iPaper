import Foundation

/// Corner radius tokens.
enum AppRadius {
    static let window: CGFloat = 18
    static let sheet: CGFloat = 16
    static let control: CGFloat = 10
    static let chip: CGFloat = 8
    static let pill: CGFloat = 999

    // Semantic aliases
    static let sheetCorner = sheet
    static let buttonCorner = control
    static let searchFieldCorner = control
    static let filterChipCorner = chip
    static let selectionCapsule = control
}
