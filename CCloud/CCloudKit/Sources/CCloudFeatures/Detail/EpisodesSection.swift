import CCloudDesignSystem
import CCloudDomain
import CCloudPresentation
import SwiftUI

/// A series' seasons and episodes, with watched marks.
struct EpisodesSection: View {
    let viewModel: MediaDetailViewModel
    /// Asks which quality to play, for episodes with more than one.
    let choose: (QualityChoice) -> Void
    let open: (MediaSource, ExternalPlayer) -> Void

    var body: some View {
        DetailSection(L10n.Detail.episodes) {
            switch viewModel.seasons {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            case .failed(let error):
                VStack(spacing: 12) {
                    Label(L10n.Detail.seasonsFailed, systemImage: error.symbolName)
                        .foregroundStyle(.secondary)
                    Button(L10n.Common.retry, systemImage: "arrow.clockwise", action: viewModel.retry)
                        .adaptiveSecondaryButtonStyle()
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            case .loaded(let seasons):
                if seasons.allSatisfy({ $0.episodes.isEmpty }) {
                    ContentUnavailableView(
                        L10n.Detail.noSeasonsTitle,
                        systemImage: "tv",
                        description: Text(L10n.Detail.noSeasonsMessage)
                    )
                } else {
                    seasonPicker(seasons)
                    if let season = viewModel.selectedSeason {
                        episodes(of: season)
                    }
                }
            }
        }
    }

    // MARK: Seasons

    @ViewBuilder
    private func seasonPicker(_ seasons: [Season]) -> some View {
        let selection = Binding<Int?>(
            get: { viewModel.selectedSeason?.id },
            set: { viewModel.selectedSeasonID = $0 }
        )
        #if os(tvOS)
        ScrollView(.horizontal) {
            HStack(spacing: 20) {
                ForEach(seasons) { season in
                    Button {
                        selection.wrappedValue = season.id
                    } label: {
                        Text(seasonTitle(season))
                            .fontWeight(season.id == selection.wrappedValue ? .bold : .regular)
                    }
                    .buttonStyle(.bordered)
                    .tint(season.id == selection.wrappedValue ? .accentColor : nil)
                }
            }
            .padding(.vertical, 12)
        }
        .scrollClipDisabled()
        .focusSection()
        #else
        if seasons.count > 1 {
            let picker = Picker(L10n.Detail.season, selection: selection) {
                ForEach(seasons) { season in
                    Text(seasonTitle(season)).tag(Int?.some(season.id))
                }
            }
            .labelsHidden()
            // A few seasons with short titles fit a segmented control; otherwise a menu. The
            // server sometimes returns one "season" per quality ("فصل اول 720 زیرنویس"), and a
            // segmented control that can't fit would widen the whole page past the screen.
            ViewThatFits(in: .horizontal) {
                if seasons.count <= 4 {
                    picker
                        .pickerStyle(.segmented)
                        .fixedSize()
                }
                picker
                    .pickerStyle(.menu)
                    .fixedSize(horizontal: false, vertical: true)
                    // A Persian season name sits at the right edge.
                    .naturalDirection(of: viewModel.selectedSeason.map(seasonTitle) ?? "")
            }
        }
        #endif
    }

    private func seasonTitle(_ season: Season) -> String {
        season.title.isEmpty ? L10n.Detail.seasonNumber(season.number) : season.title
    }

    // MARK: Episodes

    @ViewBuilder
    private func episodes(of season: Season) -> some View {
        #if os(tvOS)
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 40) {
                ForEach(season.episodes) { episode in
                    Button {
                        play(episode, in: season)
                    } label: {
                        EpisodeCard(episode: episode, isWatched: viewModel.isWatched(episode, in: season))
                    }
                    .buttonStyle(.borderless)
                    .disabled(episode.sources.isEmpty)
                    .contextMenu { episodeMenu(episode, in: season) }
                }
            }
            .padding(.vertical, 24)
        }
        .scrollClipDisabled()
        .focusSection()
        #else
        LazyVStack(spacing: 0) {
            ForEach(season.episodes) { episode in
                EpisodeRow(episode: episode, isWatched: viewModel.isWatched(episode, in: season)) {
                    play(episode, in: season)
                } menu: {
                    episodeMenu(episode, in: season)
                }
                if episode.id != season.episodes.last?.id {
                    Divider()
                }
            }
        }
        #endif
    }

    @ViewBuilder
    private func episodeMenu(_ episode: Episode, in season: Season) -> some View {
        if episode.sources.count > 1 {
            Section(L10n.Detail.qualities) {
                ForEach(episode.sources) { source in
                    Button(L10n.Detail.playQuality(source.quality), systemImage: "play") {
                        viewModel.play(source, episode: episode, in: season)
                    }
                }
            }
        }
        let isWatched = viewModel.isWatched(episode, in: season)
        Button(
            isWatched ? L10n.Detail.markUnwatched : L10n.Detail.markWatched,
            systemImage: isWatched ? "eye.slash" : "eye"
        ) {
            viewModel.toggleWatched(episode, in: season)
        }
        if let source = episode.sources.first {
            SourceActions(source: source, open: open)
        }
    }

    private func play(_ episode: Episode, in season: Season) {
        if episode.sources.count == 1, let source = episode.sources.first {
            viewModel.play(source, episode: episode, in: season)
        } else if !episode.sources.isEmpty {
            choose(QualityChoice(season: season, episode: episode))
        }
    }
}

/// The server's title (which usually names the episode, e.g. "قسمت 3"), or "Episode 3".
private func episodeTitle(_ episode: Episode) -> String {
    episode.title.isEmpty ? L10n.Detail.episodeNumber(episode.number) : episode.title
}

#if !os(tvOS)
/// An episode in the list: thumbnail, number and title, duration, watched mark.
private struct EpisodeRow<Menu: View>: View {
    let episode: Episode
    let isWatched: Bool
    let play: () -> Void
    @ViewBuilder let menu: Menu

    var body: some View {
        HStack(spacing: 14) {
            Button(action: play) {
                HStack(spacing: 14) {
                    ZStack {
                        RemoteImage(url: episode.imageURL) {
                            ArtworkPlaceholder(title: episodeTitle(episode), systemImage: "play.rectangle", showsTitle: false)
                        }
                        Image(systemName: "play.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .shadow(radius: 3)
                    }
                    .frame(width: 128, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(episodeTitle(episode))
                            .appFont(.body, weight: .semibold)
                            .lineLimit(2)
                        HStack(spacing: 6) {
                            if isWatched {
                                Label(L10n.Detail.watched, systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.tint)
                            }
                            if let duration = episode.duration {
                                Text(duration)
                            }
                            if episode.sources.count > 1 {
                                Text(L10n.Detail.qualityCount(episode.sources.count))
                            }
                        }
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                    }
                    // A Persian title and its facts sit at the right edge of the column.
                    .naturalDirection(of: episodeTitle(episode))
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
                .opacity(isWatched ? 0.75 : 1)
            }
            .buttonStyle(.plain)
            .disabled(episode.sources.isEmpty)

            SwiftUI.Menu {
                menu
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
        .padding(.vertical, 10)
        .contextMenu { menu }
    }
}
#endif

#if os(tvOS)
/// An episode on the Apple TV shelf.
private struct EpisodeCard: View {
    let episode: Episode
    let isWatched: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            RemoteImage(url: episode.imageURL) {
                ArtworkPlaceholder(title: episodeTitle(episode), systemImage: "play.rectangle", showsTitle: false)
            }
            .frame(width: 400, height: 225)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .topTrailing) {
                if isWatched {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .tint)
                        .padding(12)
                }
            }
            .hoverEffect(.highlight)

            VStack(alignment: .leading, spacing: 4) {
                Text(episodeTitle(episode))
                    .appFont(.callout, weight: .semibold)
                    .lineLimit(1)
                if let duration = episode.duration {
                    Text(duration)
                        .appFont(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 400, alignment: .leading)
            .environment(\.layoutDirection, episodeTitle(episode).naturalLayoutDirection)
        }
    }
}
#endif
