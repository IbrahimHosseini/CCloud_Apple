import SwiftUI

public extension String {
    /// The direction the text reads in, from its first letter: right to left for Persian,
    /// Arabic and Hebrew, left to right otherwise.
    var naturalLayoutDirection: LayoutDirection {
        for scalar in unicodeScalars where scalar.properties.isAlphabetic {
            switch scalar.value {
            case 0x0590...0x08FF, 0xFB1D...0xFDFF, 0xFE70...0xFEFF:
                return .rightToLeft
            default:
                return .leftToRight
            }
        }
        return .leftToRight
    }
}

public extension View {
    /// Lays out `text` in its own reading direction, so a Persian description from the API
    /// is right-aligned even in the English UI (and an English one left-aligned in Persian).
    func naturalDirection(of text: String) -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.layoutDirection, text.naturalLayoutDirection)
    }
}
