import SwiftUI

// Liquid Glass on OS 26 and later, the previous materials before that.

public extension View {
    /// A glass background in `shape`, or an ultra-thin material before OS 26.
    @ViewBuilder
    func adaptiveGlass<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }

    /// The primary action style: prominent glass, or bordered prominent before OS 26.
    @ViewBuilder
    func adaptiveProminentButtonStyle() -> some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }

    /// The secondary action style: glass, or bordered before OS 26.
    @ViewBuilder
    func adaptiveSecondaryButtonStyle() -> some View {
        if #available(iOS 26.0, macOS 26.0, tvOS 26.0, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }
}
