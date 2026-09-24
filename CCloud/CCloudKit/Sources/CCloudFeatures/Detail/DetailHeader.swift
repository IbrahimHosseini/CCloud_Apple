import CCloudDesignSystem
import CCloudDomain
import SwiftUI

/// The top of the detail page: artwork, title, facts and the main actions.
struct DetailHeader<Actions: View>: View {
    let item: MediaItem
    let isWide: Bool
    @ViewBuilder let actions: Actions

    var body: some View {
        #if os(tvOS)
        tvLayout
        #else
        standardLayout
        #endif
    }

    // MARK: iPhone, iPad, Mac

    #if !os(tvOS)
    private var standardLayout: some View {
        ZStack(alignment: .bottomLeading) {
            backdrop
            HStack(alignment: .bottom, spacing: isWide ? 24 : 16) {
                PosterArtwork(item: item)
                    .frame(width: isWide ? 180 : 112)
                    .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
                info
            }
            .padding(.horizontal, Metrics.screenPadding)
            .padding(.bottom, 4)
        }
    }

    private var backdrop: some View {
        RemoteImage(url: item.coverURL ?? item.posterURL) {
            LinearGradient(colors: Palette.placeholderGradient(seed: item.title), startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .frame(height: isWide ? 380 : 300)
        .overlay {
            // Fade the artwork into the page so the text below stays readable.
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: 0.3),
                    .init(color: backgroundColor.opacity(0.85), location: 0.72),
                    .init(color: backgroundColor, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .modifier(BackdropExtension())
        .accessibilityHidden(true)
    }

    private var backgroundColor: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.title.isEmpty ? L10n.Common.untitled : item.title)
                .appFont(isWide ? .largeTitle : .title2, weight: .bold)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
            MetadataLine(item: item)
            HStack(spacing: 10) {
                actions
            }
            .controlSize(isWide ? .large : .regular)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    #endif

    // MARK: Apple TV

    #if os(tvOS)
    private var tvLayout: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text(item.title.isEmpty ? L10n.Common.untitled : item.title)
                .appFont(.title, weight: .bold)
                .lineLimit(2)
            MetadataLine(item: item)
            HStack(spacing: 24) {
                actions
            }
            .focusSection()
        }
        .frame(maxWidth: 1100, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 380)
    }
    #endif
}

/// Year, duration, kind and the IMDb rating on one line.
private struct MetadataLine: View {
    let item: MediaItem

    var body: some View {
        HStack(spacing: 10) {
            if let rating = item.imdbRating {
                HStack(spacing: 4) {
                    Text(L10n.Detail.imdb)
                        .appFont(.caption, weight: .heavy)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Palette.imdbYellow, in: RoundedRectangle(cornerRadius: 3))
                        .foregroundStyle(.black)
                    Text(rating, format: .number.precision(.fractionLength(1)))
                        .appFont(.subheadline, weight: .semibold)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(L10n.Detail.imdbRating(rating.formatted(.number.precision(.fractionLength(1)))))
            }
            // One Text per fact: a Persian fact (e.g. the API's "فصل 1") in a single joined
            // string would flip the whole line to right-to-left order.
            HStack(spacing: 6) {
                ForEach(Array(facts.enumerated()), id: \.offset) { index, fact in
                    if index > 0 {
                        Text(verbatim: "·")
                    }
                    Text(fact)
                        .lineLimit(1)
                }
            }
            .appFont(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var facts: [String] {
        [
            item.year.map { $0.formatted(.number.grouping(.never)) },
            item.duration,
            L10n.Kind.name(item.kind),
        ].compactMap { $0 }
    }
}

#if os(tvOS)
/// The title's artwork filling the screen behind the page, darkened for legibility.
struct TVBackdrop: View {
    let item: MediaItem

    /// Many titles have no wide cover, and a portrait poster stretched to 4K looks soft;
    /// blurring it reads as intentional.
    private var isPosterStretched: Bool {
        item.coverURL == nil || item.coverURL == item.posterURL
    }

    var body: some View {
        RemoteImage(url: item.backdropURL) {
            LinearGradient(colors: Palette.placeholderGradient(seed: item.title), startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .blur(radius: isPosterStretched ? 30 : 0, opaque: true)
        .overlay {
            LinearGradient(
                colors: [.black.opacity(0.2), .black.opacity(0.75), .black.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
#endif

/// Lets the artwork extend under the navigation bar with OS 26's background extension.
private struct BackdropExtension: ViewModifier {
    func body(content: Content) -> some View {
        #if os(tvOS)
        content
        #else
        if #available(iOS 26.0, macOS 26.0, *) {
            content.backgroundExtensionEffect()
        } else {
            content
        }
        #endif
    }
}
