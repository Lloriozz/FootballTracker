import SwiftUI

/// Semantic color and typography tokens for the app.
/// Keeping colors here prevents one-off hex values from spreading through feature screens.
enum Theme {
    // MARK: - New Green Palette
    static let primaryLight = Color(hex: "#EAEF9D")
    static let secondaryLight = Color(hex: "#C1D95C")
    static let accent = Color(hex: "#80B155")
    static let primaryDark = Color(hex: "#498428")
    static let secondaryDark = Color(hex: "#336A29")

    // MARK: - Dark Mode Foundations
    /// Main deep background color (blended with black for contrast)
    static let bgPrimary = Color(red: 0.0, green: 0.12, blue: 0.05) // Very dark green
    static let bgSecondary = Color(red: 0.0, green: 0.06, blue: 0.02) // Near black

    /// Common translucent fill for glass surfaces.
    static let glassFill = Color.black.opacity(0.35)

    /// Hairline stroke that gives glass components a visible edge.
    static let glassStroke = Color.white.opacity(0.16)

    /// Accent reserved for live match states.
    static let accentLive = Color(hex: "#FF5252") // Red

    /// Primary foreground text color.
    static let textPrimary = Color.white

    /// Secondary foreground text color for metadata and muted labels.
    static let textSecondary = Color.white.opacity(0.58)

    /// Full-screen app background used by onboarding and home screens.
    static var appBackground: LinearGradient {
        LinearGradient(
            colors: [bgPrimary, bgSecondary],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension Font {
    /// Convenience helper for SF Rounded-style text throughout the app.
    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}
