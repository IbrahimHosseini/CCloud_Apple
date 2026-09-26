import CCloudDomain
import Foundation
import Observation

/// The detail page of a movie or a series.
@MainActor
@Observable
public final class MediaDetailViewModel {
    public let item: MediaItem
    /// Only loaded for series.
    public private(set) var seasons: LoadState<[Season]> = .idle
    public var selectedSeasonID: Int?

    @ObservationIgnored private let favorites: FavoritesLibrary
    @ObservationIgnored private let watchHistory: WatchHistoryLibrary
    @ObservationIgnored private let fetchSeasons: FetchSeasonsUseCase
    @ObservationIgnored private let playback: any PlaybackLauncher
    @ObservationIgnored private var seasonsTask: Task<Void, Never>?

    public init(
        item: MediaItem,
        favorites: FavoritesLibrary,
        watchHistory: WatchHistoryLibrary,
        fetchSeasons: FetchSeasonsUseCase,
        playback: any PlaybackLauncher
    ) {
        self.item = item
        self.favorites = favorites
        self.watchHistory = watchHistory
        self.fetchSeasons = fetchSeasons
        self.playback = playback
    }

    public func start() {
        guard item.kind == .series, seasons.isIdle else { return }
        loadSeasons()
    }

    public func retry() {
        loadSeasons()
    }

    // MARK: Favorites

    public var isFavorite: Bool { favorites.contains(item.id) }

    public func toggleFavorite() {
        favorites.toggle(item)
    }

    public var playlists: [Playlist] { favorites.book.playlists }

    public var memberships: Set<PlaylistID> { favorites.playlists(containing: item.id) }

    /// Puts the title into exactly these playlists, adding it to the favorites if needed.
    public func setMemberships(_ playlists: Set<PlaylistID>) {
        if !playlists.isEmpty && !isFavorite {
            favorites.add(item)
        }
        favorites.setMembership(of: item.id, to: playlists)
    }

    public func createPlaylist(named name: String) throws(PlaylistError) -> Playlist {
        try favorites.createPlaylist(named: name)
    }

    // MARK: Movie playback

    public var sources: [MediaSource] { item.sources }

    /// What "Play" starts: the sharpest source that isn't a trailer.
    public var preferredSource: MediaSource? { item.sources.preferredForPlayback }

    public func play(_ source: MediaSource) {
        playback.play(PlaybackRequest(title: item.title, source: source, artworkURL: item.backdropURL))
    }

    // MARK: Series

    public var selectedSeason: Season? {
        guard let seasons = seasons.value else { return nil }
        return seasons.first { $0.id == selectedSeasonID } ?? seasons.first
    }

    public func reference(for episode: Episode, in season: Season) -> EpisodeReference {
        EpisodeReference(seriesID: item.serverID, seasonID: season.id, episodeID: episode.id)
    }

    public func isWatched(_ episode: Episode, in season: Season) -> Bool {
        watchHistory.isWatched(reference(for: episode, in: season))
    }

    public func toggleWatched(_ episode: Episode, in season: Season) {
        let reference = reference(for: episode, in: season)
        if watchHistory.isWatched(reference) {
            watchHistory.markUnwatched(reference)
        } else {
            watchHistory.markWatched(reference)
        }
    }

    public func play(_ source: MediaSource, episode: Episode, in season: Season) {
        let context = EpisodeContext(
            reference: reference(for: episode, in: season),
            seasonNumber: season.number,
            episodeNumber: episode.number,
            episodeTitle: episode.title
        )
        playback.play(PlaybackRequest(
            title: item.title,
            source: source,
            artworkURL: episode.imageURL ?? item.backdropURL,
            episode: context
        ))
    }

    /// The first episode not watched yet in the selected season, to offer as "Play".
    /// Trailers are skipped unless there's nothing else.
    public var nextEpisode: (season: Season, episode: Episode)? {
        guard let season = selectedSeason else { return nil }
        let playable = season.episodes.filter { !$0.sources.isEmpty }
        let episodes = playable.filter { !$0.isTrailer }
        let episode = episodes.first { !isWatched($0, in: season) } ?? episodes.first ?? playable.first
        return episode.map { (season, $0) }
    }

    private func loadSeasons() {
        seasonsTask?.cancel()
        seasons = .loading
        seasonsTask = Task { [weak self, fetchSeasons, item] in
            do {
                let seasons = try await fetchSeasons.execute(seriesID: item.serverID)
                guard let self, !Task.isCancelled else { return }
                self.seasons = .loaded(seasons)
                if self.selectedSeasonID == nil || !seasons.contains(where: { $0.id == self.selectedSeasonID }) {
                    self.selectedSeasonID = seasons.first?.id
                }
            } catch {
                guard !Task.isCancelled, let error = DomainError(presenting: error) else { return }
                self?.seasons = .failed(error)
            }
        }
    }
}
