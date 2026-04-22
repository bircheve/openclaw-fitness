import SwiftUI

extension Color {
    // MARK: - Brand Colors (from pixelated barbell logo)

    /// Primary brand purple - Deep royal blue/purple
    static let brandPrimary = Color(hex: "4318FF")

    /// Secondary brand purple - Bright purple
    static let brandSecondary = Color(hex: "7B61FF")

    /// Accent purple - Light periwinkle
    static let brandAccent = Color(hex: "B8A9FF")

    /// Light lavender - Very light purple
    static let brandLavender = Color(hex: "E0D9FF")

    /// Pure white for contrast
    static let brandWhite = Color.white

    // MARK: - Gradient Combinations

    static let brandGradient = LinearGradient(
        colors: [brandPrimary, brandSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let brandGradientHorizontal = LinearGradient(
        colors: [brandPrimary, brandSecondary],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let softGradient = LinearGradient(
        colors: [brandSecondary, brandAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Background Gradients for Onboarding

    static func onboardingBackground(_ step: Int) -> LinearGradient {
        let colors: [[Color]] = [
            [brandPrimary.opacity(0.3), brandSecondary.opacity(0.4)],      // Welcome
            [brandSecondary.opacity(0.3), brandAccent.opacity(0.3)],        // Name
            [brandAccent.opacity(0.3), brandLavender.opacity(0.4)],         // Age
            [brandLavender.opacity(0.3), brandPrimary.opacity(0.25)],       // Gym
            [brandPrimary.opacity(0.25), brandSecondary.opacity(0.3)]       // Preferences
        ]

        let index = min(step, colors.count - 1)
        return LinearGradient(
            colors: colors[index],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Semantic Feedback Colors
    // Apple system palette (matches native iOS toast / alert conventions).

    /// Success — matches iOS system green.
    static let feedbackSuccess = Color(hex: "34C759")

    /// Info — iOS system blue. Intentionally NOT brandPrimary: info needs to read
    /// as "neutral system acknowledgment," not a brand moment.
    static let feedbackInfo = Color(hex: "0A84FF")

    /// Warning — iOS system orange.
    static let feedbackWarning = Color(hex: "FF9500")

    /// Error — iOS system red.
    static let feedbackError = Color(hex: "FF453A")

    // MARK: - Helper initializer for hex colors

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
