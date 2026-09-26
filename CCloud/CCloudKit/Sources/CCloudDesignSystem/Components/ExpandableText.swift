import SwiftUI

/// Long text cut to a few lines, with "Show More" when it doesn't fit.
public struct ExpandableText: View {
    private let text: String
    private let lineLimit: Int

    @State private var isExpanded = false
    @State private var fullHeight: CGFloat = 0
    @State private var limitedHeight: CGFloat = 0

    public init(_ text: String, lineLimit: Int = 4) {
        self.text = text
        self.lineLimit = lineLimit
    }

    private var isTruncated: Bool { fullHeight > limitedHeight + 1 }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
                .lineLimit(isExpanded ? nil : lineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .naturalDirection(of: text)
                .background {
                    // Measure the text both ways to know whether it's cut off.
                    ZStack {
                        Text(text).fixedSize(horizontal: false, vertical: true)
                            .onGeometryChange(for: CGFloat.self, of: \.size.height) { fullHeight = $0 }
                        Text(text).lineLimit(lineLimit).fixedSize(horizontal: false, vertical: true)
                            .onGeometryChange(for: CGFloat.self, of: \.size.height) { limitedHeight = $0 }
                    }
                    .hidden()
                }
                .animation(.easeInOut(duration: 0.2), value: isExpanded)

            if isTruncated {
                Button(isExpanded ? L10n.Common.showLess : L10n.Common.showMore) {
                    isExpanded.toggle()
                }
                #if os(tvOS)
                .buttonStyle(.bordered)
                #else
                .buttonStyle(.borderless)
                #endif
                .appFont(.subheadline, weight: .semibold)
            }
        }
    }
}
