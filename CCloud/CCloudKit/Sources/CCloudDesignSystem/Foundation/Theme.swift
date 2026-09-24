import CCloudDomain
import SwiftUI

public extension RGBAColor {
    var swiftUIColor: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

public extension Appearance {
    /// `nil` follows the system.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

public extension View {
    /// Applies the user's appearance, accent color and font to a whole window.
    func appTheme(_ settings: AppSettings) -> some View {
        tint(settings.accentColor.color?.swiftUIColor)
            .preferredColorScheme(settings.appearance.colorScheme)
            .environment(\.fontChoice, settings.font)
            .font(.app(.body, choice: settings.font))
    }
}

/// Colors used for placeholders and badges.
public enum Palette {
    public static let imdbYellow = Color(red: 0.96, green: 0.77, blue: 0.09)

    /// A stable pair of gradient colors for artwork placeholders, derived from `seed`.
    public static func placeholderGradient(seed: String) -> [Color] {
        let hues: [Double] = [0.58, 0.62, 0.68, 0.75, 0.83, 0.95, 0.05, 0.12, 0.45, 0.52]
        let hash = seed.unicodeScalars.reduce(5381) { ($0 << 5) &+ $0 &+ Int($1.value) }
        let hue = hues[abs(hash) % hues.count]
        return [
            Color(hue: hue, saturation: 0.55, brightness: 0.55),
            Color(hue: (hue + 0.08).truncatingRemainder(dividingBy: 1), saturation: 0.65, brightness: 0.30),
        ]
    }
}
