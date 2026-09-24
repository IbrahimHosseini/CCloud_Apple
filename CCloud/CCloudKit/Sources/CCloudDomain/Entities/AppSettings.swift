import Foundation

/// Everything the user can customize. Persisted as a whole.
public struct AppSettings: Codable, Hashable, Sendable {
    public var appearance: Appearance
    public var accentColor: AccentColorOption
    public var font: FontChoice
    public var player: PlayerSettings
    public var subtitles: SubtitleStyle

    public init(
        appearance: Appearance = .system,
        accentColor: AccentColorOption = .system,
        font: FontChoice = .system,
        player: PlayerSettings = PlayerSettings(),
        subtitles: SubtitleStyle = SubtitleStyle()
    ) {
        self.appearance = appearance
        self.accentColor = accentColor
        self.font = font
        self.player = player
        self.subtitles = subtitles
    }

    public static let `default` = AppSettings()

    // Decode field by field so settings saved by an older version keep working
    // when a field is added later.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppSettings.default
        appearance = (try? container.decode(Appearance.self, forKey: .appearance)) ?? defaults.appearance
        accentColor = (try? container.decode(AccentColorOption.self, forKey: .accentColor)) ?? defaults.accentColor
        font = (try? container.decode(FontChoice.self, forKey: .font)) ?? defaults.font
        player = (try? container.decode(PlayerSettings.self, forKey: .player)) ?? defaults.player
        subtitles = (try? container.decode(SubtitleStyle.self, forKey: .subtitles)) ?? defaults.subtitles
    }
}

public enum Appearance: String, Codable, Hashable, Sendable, CaseIterable {
    case system
    case light
    case dark
}

/// The accent colors offered by the Android app, plus the platform's own accent.
public enum AccentColorOption: String, Codable, Hashable, Sendable, CaseIterable {
    case system
    case purple
    case teal
    case red
    case pink
    case purpleGrey
    case green
    case blue
    case yellow

    /// `nil` for `.system`, which follows the platform accent color.
    public var color: RGBAColor? {
        switch self {
        case .system: nil
        case .purple: RGBAColor(hex: 0x6650A4)
        case .teal: RGBAColor(hex: 0x006A6A)
        case .red: RGBAColor(hex: 0xBA1A1A)
        case .pink: RGBAColor(hex: 0x7D5260)
        case .purpleGrey: RGBAColor(hex: 0x625B71)
        case .green: RGBAColor(hex: 0x006D32)
        case .blue: RGBAColor(hex: 0x3B5BA9)
        case .yellow: RGBAColor(hex: 0xFFB700)
        }
    }
}

public enum FontChoice: String, Codable, Hashable, Sendable, CaseIterable {
    /// San Francisco (and the system's Arabic-script font for Persian).
    case system
    /// The bundled Vazirmatn family, designed for Persian text.
    case vazirmatn
}

public struct PlayerSettings: Codable, Hashable, Sendable {
    /// Seconds skipped by the seek-forward / seek-back controls.
    public var seekInterval: Int

    public static let seekIntervalRange = 5...30

    public init(seekInterval: Int = 10) {
        self.seekInterval = seekInterval.clamped(to: Self.seekIntervalRange)
    }
}

public struct SubtitleStyle: Codable, Hashable, Sendable {
    public var textColor: SubtitleTextColor
    public var background: SubtitleBackground
    /// Text size in percent of the player's default size.
    public var sizePercent: Int

    public static let sizePercentRange = 50...250

    public init(textColor: SubtitleTextColor = .yellow, background: SubtitleBackground = .glass, sizePercent: Int = 100) {
        self.textColor = textColor
        self.background = background
        self.sizePercent = sizePercent.clamped(to: Self.sizePercentRange)
    }
}

public enum SubtitleTextColor: String, Codable, Hashable, Sendable, CaseIterable {
    case yellow, white, black, red, blue, green

    public var color: RGBAColor {
        switch self {
        case .yellow: RGBAColor(hex: 0xFFFF00)
        case .white: RGBAColor(hex: 0xFFFFFF)
        case .black: RGBAColor(hex: 0x000000)
        case .red: RGBAColor(hex: 0xFF0000)
        case .blue: RGBAColor(hex: 0x0000FF)
        case .green: RGBAColor(hex: 0x00FF00)
        }
    }
}

public enum SubtitleBackground: String, Codable, Hashable, Sendable, CaseIterable {
    /// No box behind the text.
    case none
    /// Half-transparent black.
    case glass
    case white, black, red, blue, green

    public var color: RGBAColor {
        switch self {
        case .none: RGBAColor(red: 0, green: 0, blue: 0, alpha: 0)
        case .glass: RGBAColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        case .white: RGBAColor(hex: 0xFFFFFF)
        case .black: RGBAColor(hex: 0x000000)
        case .red: RGBAColor(hex: 0xFF0000)
        case .blue: RGBAColor(hex: 0x0000FF)
        case .green: RGBAColor(hex: 0x00FF00)
        }
    }
}

/// A platform-independent color with components in 0...1.
public struct RGBAColor: Codable, Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// `hex` is 0xRRGGBB.
    public init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            alpha: alpha
        )
    }

    /// 0xRRGGBB, ignoring alpha.
    public var rgbHex: UInt32 {
        func byte(_ component: Double) -> UInt32 { UInt32((component.clamped(to: 0...1) * 255).rounded()) }
        return byte(red) << 16 | byte(green) << 8 | byte(blue)
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
