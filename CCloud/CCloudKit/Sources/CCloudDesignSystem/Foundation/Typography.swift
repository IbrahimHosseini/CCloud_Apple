import CCloudDomain
import CoreText
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public extension EnvironmentValues {
    /// The font family chosen in Settings.
    @Entry var fontChoice: FontChoice = .system
}

public extension View {
    /// Sets a text style in the font family chosen in Settings.
    func appFont(_ style: Font.TextStyle, weight: Font.Weight? = nil) -> some View {
        modifier(AppFontModifier(style: style, weight: weight))
    }
}

public extension View {
    /// Centers a pill's, button's or badge's text vertically when Vazirmatn is the font.
    ///
    /// Vazirmatn reserves far more room above the baseline than below it (to fit Persian
    /// marks), so Latin text sits about a tenth of its size above the middle of its line box,
    /// and above the middle of the control it is in. This moves the drawing down, without
    /// changing the layout, so the control keeps its size. Apply it to the label's `Text`,
    /// not to the icon beside it. `style` is the text style of the label; it does nothing in
    /// the system font.
    func centeredLabel(_ style: Font.TextStyle = .body) -> some View {
        modifier(CenteredLabelModifier(style: style))
    }
}

private struct CenteredLabelModifier: ViewModifier {
    @Environment(\.fontChoice) private var choice
    @ScaledMetric private var size: CGFloat

    init(style: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: style.basePointSize, relativeTo: style)
    }

    func body(content: Content) -> some View {
        content.offset(y: choice == .vazirmatn ? size * 0.1 : 0)
    }
}

private struct AppFontModifier: ViewModifier {
    let style: Font.TextStyle
    let weight: Font.Weight?
    @Environment(\.fontChoice) private var choice

    func body(content: Content) -> some View {
        content.font(.app(style, choice: choice, weight: weight))
    }
}

public extension Font {
    /// A text style in the given family. Custom fonts scale with Dynamic Type like the system font.
    static func app(_ style: Font.TextStyle, choice: FontChoice, weight: Font.Weight? = nil) -> Font {
        switch choice {
        case .system:
            return .system(style, weight: weight)
        case .vazirmatn:
            let weight = weight ?? style.defaultWeight
            return .custom(Vazirmatn.postScriptName(for: weight), size: style.basePointSize, relativeTo: style)
        }
    }
}

/// The bundled Vazirmatn family.
public enum Vazirmatn {
    static let faces = ["Thin", "ExtraLight", "Light", "Regular", "Medium", "SemiBold", "Bold", "ExtraBold", "Black"]

    static func postScriptName(for weight: Font.Weight) -> String {
        let face = switch weight {
        case .ultraLight: "ExtraLight"
        case .thin: "Thin"
        case .light: "Light"
        case .medium: "Medium"
        case .semibold: "SemiBold"
        case .bold: "Bold"
        case .heavy: "ExtraBold"
        case .black: "Black"
        default: "Regular"
        }
        return "Vazirmatn-\(face)"
    }

    /// Makes the bundled font files available to the app. Safe to call more than once.
    @MainActor
    public static func register() {
        guard !isRegistered else { return }
        isRegistered = true
        for face in faces {
            guard let url = Bundle.module.url(forResource: "Vazirmatn-\(face)", withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    @MainActor private static var isRegistered = false
}

extension Font.TextStyle {
    var defaultWeight: Font.Weight {
        self == .headline ? .semibold : .regular
    }

    /// The platform's size for this style at the default Dynamic Type size.
    var basePointSize: CGFloat {
        #if canImport(UIKit)
        let traits = UITraitCollection(preferredContentSizeCategory: .large)
        return UIFont.preferredFont(forTextStyle: platformStyle, compatibleWith: traits).pointSize
        #elseif canImport(AppKit)
        return NSFont.preferredFont(forTextStyle: platformStyle).pointSize
        #endif
    }

    #if canImport(UIKit)
    private var platformStyle: UIFont.TextStyle {
        switch self {
        #if os(tvOS)
        case .largeTitle: .title1 // tvOS has no large title style
        #else
        case .largeTitle: .largeTitle
        #endif
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }
    #elseif canImport(AppKit)
    private var platformStyle: NSFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }
    #endif
}
