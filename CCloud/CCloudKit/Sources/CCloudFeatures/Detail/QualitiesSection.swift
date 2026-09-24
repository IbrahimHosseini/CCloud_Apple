import CCloudDesignSystem
import CCloudDomain
import SwiftUI

/// A movie's playable files, one row per quality, with ways to open them elsewhere.
struct QualitiesSection: View {
    let sources: [MediaSource]
    let play: (MediaSource) -> Void
    let open: (MediaSource, ExternalPlayer) -> Void

    var body: some View {
        DetailSection(L10n.Detail.qualities) {
            if sources.isEmpty {
                ContentUnavailableView(
                    L10n.Detail.noSourcesTitle,
                    systemImage: "film.stack",
                    description: Text(L10n.Detail.noSourcesMessage)
                )
            } else {
                #if os(tvOS)
                ScrollView(.horizontal) {
                    HStack(spacing: 32) {
                        ForEach(sources) { source in
                            Menu {
                                SourceActions(source: source, open: open)
                            } label: {
                                Label(source.quality, systemImage: "play.rectangle")
                            } primaryAction: {
                                play(source)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                }
                .scrollClipDisabled()
                .focusSection()
                #else
                VStack(spacing: 0) {
                    ForEach(sources) { source in
                        SourceRow(source: source, play: { play(source) }, open: open)
                        if source.id != sources.last?.id {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .background(.fill.quinary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                #endif
            }
        }
    }
}

#if !os(tvOS)
private struct SourceRow: View {
    let source: MediaSource
    let play: () -> Void
    let open: (MediaSource, ExternalPlayer) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: play) {
                HStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(source.quality)
                            .appFont(.body, weight: .semibold)
                        if !source.format.isEmpty, source.format.lowercased() != "unknown" {
                            Text(source.format.uppercased())
                                .appFont(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Detail.playQuality(source.quality))

            Menu {
                SourceActions(source: source, open: open)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .menuIndicator(.hidden)
            .fixedSize()
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Actions.moreOptions)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contextMenu {
            SourceActions(source: source, open: open)
        }
    }
}
#endif

/// Everything the user can do with a file besides playing it here.
struct SourceActions: View {
    let source: MediaSource
    let open: (MediaSource, ExternalPlayer) -> Void

    var body: some View {
        Section(L10n.Actions.openIn) {
            ForEach(ExternalPlayer.allCases) { player in
                Button(player.actionTitle, systemImage: "arrow.up.forward.app") {
                    open(source, player)
                }
            }
        }
        #if !os(tvOS)
        Section {
            Link(destination: source.url) {
                Label(L10n.Actions.downloadInBrowser, systemImage: "arrow.down.circle")
            }
            Button(L10n.Actions.copyLink, systemImage: "link") {
                Clipboard.copy(source.url)
            }
            ShareLink(item: source.url) {
                Label(L10n.Actions.share, systemImage: "square.and.arrow.up")
            }
        }
        #endif
    }
}
