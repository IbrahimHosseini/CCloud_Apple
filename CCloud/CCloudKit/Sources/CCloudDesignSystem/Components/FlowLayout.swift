import SwiftUI

/// Lays subviews out in rows, wrapping to a new row when one is full (for chips).
public struct FlowLayout: Layout {
    private let spacing: CGFloat
    private let rowSpacing: CGFloat

    public init(spacing: CGFloat = Metrics.chipSpacing, rowSpacing: CGFloat = Metrics.chipSpacing) {
        self.spacing = spacing
        self.rowSpacing = rowSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(for: subviews, maxWidth: proposal.width ?? .infinity)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + rowSpacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let isRightToLeft = subviews.layoutDirection == .rightToLeft
        var y = bounds.minY
        for row in rows(for: subviews, maxWidth: bounds.width) {
            // How far along the row's start edge (the right one when reading right to left).
            var offset: CGFloat = 0
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                let x = isRightToLeft ? bounds.maxX - offset - size.width : bounds.minX + offset
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2), proposal: ProposedViewSize(size))
                offset += size.width + spacing
            }
            y += row.height + rowSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let widthWithItem = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if widthWithItem > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty {
            rows.append(current)
        }
        return rows
    }
}

/// A rounded label for a genre or country.
public struct Chip: View {
    private let title: String
    private let systemImage: String?

    public init(_ title: String, systemImage: String? = nil) {
        self.title = title
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .imageScale(.small)
            }
            Text(title)
                .centeredLabel(.subheadline)
        }
        .appFont(.subheadline, weight: .medium)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.fill.tertiary, in: Capsule())
    }
}
