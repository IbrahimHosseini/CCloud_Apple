import SwiftUI

#if canImport(UIKit)
import UIKit
public typealias PlatformFont = UIFont
#elseif canImport(AppKit)
import AppKit
public typealias PlatformFont = NSFont
#endif

/// Sizes that differ per platform, so shared views look native on each.
public enum Metrics {
    #if os(tvOS)
    public static let screenPadding: CGFloat = 0 // tvOS applies its own safe area insets
    public static let gridSpacing: CGFloat = 48
    public static let rowSpacing: CGFloat = 64
    public static let posterMinWidth: CGFloat = 230
    public static let posterMaxWidth: CGFloat = 280
    public static let posterCornerRadius: CGFloat = 16
    public static let sectionSpacing: CGFloat = 56
    public static let chipSpacing: CGFloat = 16
    #elseif os(macOS)
    public static let screenPadding: CGFloat = 20
    public static let gridSpacing: CGFloat = 20
    public static let rowSpacing: CGFloat = 24
    public static let posterMinWidth: CGFloat = 150
    public static let posterMaxWidth: CGFloat = 190
    public static let posterCornerRadius: CGFloat = 8
    public static let sectionSpacing: CGFloat = 28
    public static let chipSpacing: CGFloat = 8
    #else
    public static let screenPadding: CGFloat = 16
    public static let gridSpacing: CGFloat = 12
    public static let rowSpacing: CGFloat = 20
    public static let posterMinWidth: CGFloat = 105
    public static let posterMaxWidth: CGFloat = 180
    public static let posterCornerRadius: CGFloat = 10
    public static let sectionSpacing: CGFloat = 28
    public static let chipSpacing: CGFloat = 8
    #endif

    /// Movie posters are 2:3.
    public static let posterAspectRatio: CGFloat = 2.0 / 3.0

    /// Grid columns for posters, adapting to the available width.
    public static func posterColumns(regularWidth: Bool = false) -> [GridItem] {
        #if os(iOS)
        let minimum = regularWidth ? 150 : posterMinWidth
        #else
        let minimum = posterMinWidth
        #endif
        return [GridItem(.adaptive(minimum: minimum, maximum: posterMaxWidth), spacing: gridSpacing, alignment: .top)]
    }
}

public extension View {
    /// Applies `transform` only on the platforms where `condition` holds, keeping one view tree.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
