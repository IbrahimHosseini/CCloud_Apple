import CCloudDomain
@testable import CCloudPresentation
import Foundation
import Testing

@MainActor
@Suite("Screen ViewModels")
struct ScreenViewModelTests {
    private func makeLibraries() -> (FavoritesLibrary, WatchHistoryLibrary, MemoryFavoritesRepository) {
        let favoritesRepository = MemoryFavoritesRepository()
        let favorites = FavoritesLibrary(useCase: FavoritesUseCase(repository: favoritesRepository))
        let history = WatchHistoryLibrary(useCase: WatchHistoryUseCase(repository: MemoryWatchHistoryRepository()))
        return (favorites, history, favoritesRepository)
    }

    private func makeSeason(_ id: Int, number: Int, episodes: Int) -> Season {
        Season(id: id, number: number, title: "", episodes: (1...episodes).map { index in
            Episode(
                id: id * 100 + index, number: index, title: "", overview: "", duration: nil, imageURL: nil,
                sources: [MediaSource(id: index, quality: "720p", format: "mp4", url: URL(string: "https://x.example.com/\(index).mp4")!)]
            )
        })
    }

    // MARK: Search

    @Test func searchesOnSubmitAndClearsBackToBrowsing() async {
        let viewModel = SearchViewModel(
            search: SearchTitlesUseCase(repository: FakeSearchRepository(results: [.fixture(id: 1, title: "Heat")]), policy: TitleContentPolicy()),
            fetchCountries: FetchCountriesUseCase(repository: FakeCountryRepository())
        )
        viewModel.start()
        await waitUntil { viewModel.countries.value?.count == 1 }
        #expect(viewModel.isBrowsing)

        viewModel.query = "heat"
        #expect(viewModel.isBrowsing, "Without live search, typing alone doesn't search")
        viewModel.submit()
        await waitUntil { viewModel.results.value != nil }
        #expect(viewModel.results.value?.map(\.title) == ["Heat"])
        #expect(viewModel.searchedQuery == "heat")

        viewModel.clear()
        #expect(viewModel.isBrowsing)
    }

    @Test func liveSearchFollowsTyping() async {
        let viewModel = SearchViewModel(
            search: SearchTitlesUseCase(repository: FakeSearchRepository(results: [.fixture(id: 1, title: "Heat")]), policy: TitleContentPolicy()),
            fetchCountries: FetchCountriesUseCase(repository: FakeCountryRepository()),
            liveSearchDelay: .milliseconds(10)
        )
        viewModel.query = "he"
        await waitUntil { viewModel.searchedQuery == "he" }
        #expect(viewModel.results.value?.count == 1)
    }

    // MARK: Detail

    @Test func moviePlaybackUsesTheChosenSource() {
        let (favorites, history, _) = makeLibraries()
        let launcher = RecordingPlaybackLauncher()
        let movie = MediaItem.fixture(id: 3, sources: 2)
        let viewModel = MediaDetailViewModel(item: movie, favorites: favorites, watchHistory: history,
                                             fetchSeasons: FetchSeasonsUseCase(repository: FakeSeasonRepository(seasons: [])), playback: launcher)

        viewModel.play(movie.sources[1])
        #expect(launcher.requests.first?.source == movie.sources[1])
        #expect(launcher.requests.first?.episode == nil)
    }

    @Test func seriesLoadSeasonsAndSuggestTheNextUnwatchedEpisode() async {
        let (favorites, history, _) = makeLibraries()
        let launcher = RecordingPlaybackLauncher()
        let series = MediaItem.fixture(id: 8, kind: .series, sources: 0)
        let seasons = [makeSeason(1, number: 1, episodes: 3), makeSeason(2, number: 2, episodes: 2)]
        let viewModel = MediaDetailViewModel(item: series, favorites: favorites, watchHistory: history,
                                             fetchSeasons: FetchSeasonsUseCase(repository: FakeSeasonRepository(seasons: seasons)), playback: launcher)

        viewModel.start()
        await waitUntil { viewModel.seasons.value != nil }
        #expect(viewModel.selectedSeason?.id == 1)
        #expect(viewModel.nextEpisode?.episode.number == 1)

        let first = seasons[0].episodes[0]
        viewModel.toggleWatched(first, in: seasons[0])
        #expect(viewModel.isWatched(first, in: seasons[0]))
        #expect(viewModel.nextEpisode?.episode.number == 2)

        let second = seasons[0].episodes[1]
        viewModel.play(second.sources[0], episode: second, in: seasons[0])
        let context = launcher.requests.first?.episode
        #expect(context?.reference == EpisodeReference(seriesID: 8, seasonID: 1, episodeID: second.id))
        #expect(context?.seasonNumber == 1)
        #expect(context?.episodeNumber == 2)
    }

    @Test func playSkipsTrailers() async {
        let (favorites, history, _) = makeLibraries()
        let url = URL(string: "https://x.example.com/v.mkv")!
        let trailer = Episode(id: 1, number: 1, title: "تیزر", overview: "", duration: nil, imageURL: nil,
                              sources: [MediaSource(id: 1, quality: "تیزر", format: "mp4", url: url)])
        let first = Episode(id: 2, number: 2, title: "قسمت 1", overview: "", duration: nil, imageURL: nil,
                            sources: [MediaSource(id: 2, quality: "720", format: "mkv", url: url)])
        let series = MediaItem.fixture(id: 5, kind: .series, sources: 0)
        let viewModel = MediaDetailViewModel(
            item: series, favorites: favorites, watchHistory: history,
            fetchSeasons: FetchSeasonsUseCase(repository: FakeSeasonRepository(seasons: [Season(id: 9, number: 1, title: "", episodes: [trailer, first])])),
            playback: RecordingPlaybackLauncher()
        )
        viewModel.start()
        await waitUntil { viewModel.seasons.value != nil }
        #expect(viewModel.nextEpisode?.episode.id == first.id)

        let movie = MediaItem(
            serverID: 6, kind: .movie, title: "M", overview: "", year: nil, imdbRating: nil, rating: nil, duration: nil,
            posterURL: nil, coverURL: nil, genres: [], countries: [],
            sources: [MediaSource(id: 1, quality: "تیزر", format: "mp4", url: url), MediaSource(id: 2, quality: "1080 زیرنویس", format: "mkv", url: url)]
        )
        let movieViewModel = MediaDetailViewModel(item: movie, favorites: favorites, watchHistory: history,
                                                  fetchSeasons: FetchSeasonsUseCase(repository: FakeSeasonRepository(seasons: [])),
                                                  playback: RecordingPlaybackLauncher())
        #expect(movieViewModel.preferredSource?.id == 2)
    }

    @Test func choosingPlaylistsAlsoFavoritesTheTitle() throws {
        let (favorites, history, _) = makeLibraries()
        let movie = MediaItem.fixture(id: 4)
        let viewModel = MediaDetailViewModel(item: movie, favorites: favorites, watchHistory: history,
                                             fetchSeasons: FetchSeasonsUseCase(repository: FakeSeasonRepository(seasons: [])), playback: RecordingPlaybackLauncher())
        let playlist = try viewModel.createPlaylist(named: "Weekend")

        viewModel.setMemberships([playlist.id])

        #expect(viewModel.isFavorite)
        #expect(viewModel.memberships == [playlist.id])
    }

    // MARK: Favorites

    @Test func favoritesAreSavedAfterChanges() async {
        let (favorites, _, repository) = makeLibraries()
        favorites.toggle(.fixture(id: 1))
        favorites.toggle(.fixture(id: 2))
        favorites.toggle(.fixture(id: 1))

        await waitUntil { favorites.book.entries.count == 1 }
        var saved: FavoritesBook?
        for _ in 0..<200 where saved != favorites.book {
            saved = await repository.saved
            try? await Task.sleep(for: .milliseconds(5))
        }
        #expect(saved?.entries.map(\.item.serverID) == [2])
    }

    @Test func deletingTheSelectedPlaylistShowsAllFavorites() throws {
        let (favorites, _, _) = makeLibraries()
        let viewModel = FavoritesViewModel(library: favorites)
        favorites.add(.fixture(id: 1))
        let playlist = try viewModel.createPlaylist(named: "Later")
        viewModel.select(playlist.id)
        #expect(viewModel.entries.isEmpty)

        viewModel.deletePlaylist(playlist.id)
        #expect(viewModel.selectedPlaylistID == nil)
        #expect(viewModel.entries.count == 1)
    }

    @Test func duplicatePlaylistNamesAreRejected() throws {
        let (favorites, _, _) = makeLibraries()
        let viewModel = FavoritesViewModel(library: favorites)
        try viewModel.createPlaylist(named: "Later")
        #expect(throws: PlaylistError.duplicateName) {
            try viewModel.createPlaylist(named: "later")
        }
    }
}
