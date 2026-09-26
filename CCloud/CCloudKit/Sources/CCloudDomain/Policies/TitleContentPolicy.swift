import Foundation

/// Decides which catalog titles are shown.
///
/// Matches the Android app, which hides every title written in Persian script.
public struct TitleContentPolicy: Sendable {
    public var hidesPersianTitles: Bool

    public init(hidesPersianTitles: Bool = true) {
        self.hidesPersianTitles = hidesPersianTitles
    }

    public func allows(_ item: MediaItem) -> Bool {
        !(hidesPersianTitles && Self.containsPersianScript(item.title))
    }

    /// `true` if `text` contains any Arabic-script character (which Persian uses).
    public static func containsPersianScript(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x0600...0x06FF, // Arabic
                 0xFB50...0xFDFF, // Arabic Presentation Forms-A
                 0xFE70...0xFEFF: // Arabic Presentation Forms-B
                true
            default:
                false
            }
        }
    }
}
