import CCloudDomain
import SwiftUI

/// A round color sample. `nil` draws the "no color" sample.
public struct ColorSwatch: View {
    private let color: Color?
    private let isSelected: Bool
    private let size: CGFloat

    public init(color: Color?, isSelected: Bool = false, size: CGFloat = 26) {
        self.color = color
        self.isSelected = isSelected
        self.size = size
    }

    public var body: some View {
        ZStack {
            if let color {
                Circle().fill(color)
                // A checkerboard-free hint that the color may be translucent.
                Circle().strokeBorder(.primary.opacity(0.15), lineWidth: 1)
            } else {
                Circle().strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                Image(systemName: "slash.circle")
                    .foregroundStyle(.secondary)
                    .font(.system(size: size * 0.5))
            }
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.45, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1)
            }
        }
        .frame(width: size, height: size)
        .overlay {
            if isSelected {
                Circle().strokeBorder(.tint, lineWidth: 2).padding(-4)
            }
        }
        .accessibilityHidden(true)
    }
}

public extension SubtitleBackground {
    /// `nil` for no background.
    var swatchColor: Color? {
        self == .none ? nil : color.swiftUIColor
    }
}

/// A frame of "video" with a line of sample subtitle text in the chosen style.
public struct SubtitlePreview: View {
    private let style: SubtitleStyle

    public init(style: SubtitleStyle) {
        self.style = style
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hue: 0.58, saturation: 0.5, brightness: 0.45), Color(hue: 0.08, saturation: 0.6, brightness: 0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text(L10n.Settings.subtitlePreview)
                .font(.system(size: baseSize * CGFloat(style.sizePercent) / 100, weight: .medium))
                .foregroundStyle(style.textColor.color.swiftUIColor)
                .shadow(color: style.background == .none ? .black : .clear, radius: 1.5)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(style.background.color.swiftUIColor, in: RoundedRectangle(cornerRadius: 4))
                .multilineTextAlignment(.center)
                .padding(.bottom, 14)
                .padding(.horizontal, 12)
        }
        .aspectRatio(2.4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityHidden(true)
    }

    #if os(tvOS)
    private let baseSize: CGFloat = 30
    #else
    private let baseSize: CGFloat = 16
    #endif
}
