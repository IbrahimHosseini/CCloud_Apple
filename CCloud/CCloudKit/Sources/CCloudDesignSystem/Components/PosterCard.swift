import CCloudDomain
import SwiftUI

/// A title's poster with its name and year: the cell of every grid.
public struct PosterCard: View {
    private let item: MediaItem
    private let showsKind: Bool

    public init(item: MediaItem, showsKind: Bool = false) {
        self.item = item
        self.showsKind = showsKind
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: titleSpacing) {
            PosterArtwork(item: item)
                .overlay(alignment: .topTrailing) {
                    if let rating = item.imdbRating {
                        RatingBadge(rating: rating)
                            .padding(badgeInset)
                    }
                }
                #if os(tvOS)
                .hoverEffect(.highlight)
                #endif

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title.isEmpty ? L10n.Common.untitled : item.title)
                    .appFont(titleStyle, weight: .medium)
                    .foregroundStyle(.primary)
                    .lineLimit(titleLineLimit)
                    .multilineTextAlignment(.leading)
                if let caption {
                    Text(caption)
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var caption: String? {
        let parts = [
            item.year.map { $0.formatted(.number.grouping(.never)) },
            showsKind ? L10n.Kind.name(item.kind) : nil,
        ].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    #if os(tvOS)
    private let titleStyle: Font.TextStyle = .caption
    private let titleLineLimit = 1
    private let titleSpacing: CGFloat = 16
    private let badgeInset: CGFloat = 12
    #else
    private let titleStyle: Font.TextStyle = .subheadline
    private let titleLineLimit = 2
    private let titleSpacing: CGFloat = 8
    private let badgeInset: CGFloat = 6
    #endif
}

/// The 2:3 poster image with rounded corners, or a placeholder.
public struct PosterArtwork: View {
    private let url: URL?
    private let title: String
    private let kind: MediaKind

    public init(item: MediaItem) {
        url = item.posterURL
        title = item.title
        kind = item.kind
    }

    public init(url: URL?, title: String, kind: MediaKind) {
        self.url = url
        self.title = title
        self.kind = kind
    }

    public var body: some View {
        RemoteImage(url: url) {
            ArtworkPlaceholder(title: title, systemImage: kind.symbolName)
        }
        .aspectRatio(Metrics.posterAspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.posterCornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Metrics.posterCornerRadius, style: .continuous)
                .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
        }
        #if !os(tvOS)
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        #endif
    }
}

public extension MediaKind {
    /// The SF Symbol that stands for this kind.
    var symbolName: String {
        switch self {
        case .movie: "film"
        case .series: "tv"
        }
    }
}

/// "★ 7.8" on a translucent capsule.
public struct RatingBadge: View {
    private let rating: Double

    public init(rating: Double) {
        self.rating = rating
    }

    public var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .foregroundStyle(Palette.imdbYellow)
            Text(rating, format: .number.precision(.fractionLength(1)))
                .monospacedDigit()
                .centeredLabel(.caption2)
        }
        .appFont(.caption2, weight: .bold)
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.black.opacity(0.55), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.Detail.imdbRating(rating.formatted(.number.precision(.fractionLength(1)))))
    }
}

public extension View {
    /// The platform's style for tappable posters: plain on iOS and macOS, the focus
    /// "lift" on tvOS.
    func posterButtonStyle() -> some View {
        #if os(tvOS)
        buttonStyle(.borderless)
        #else
        buttonStyle(.plain)
        #endif
    }
}
