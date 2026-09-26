import CCloudData
import CCloudDesignSystem
import CCloudDomain
import CCloudFeatures
import CCloudPlayer
import CCloudPresentation
import Foundation

/// The composition root: the only place that knows every concrete type.
///
/// It builds the data layer, hands it to the domain use cases through their repository
/// protocols, and creates ViewModels on request (`ViewModelFactory`). Views never construct
/// their own dependencies, so swapping the backend (e.g. the offline demo catalog) happens
/// here and nowhere else.
@MainActor
public final class AppContainer: ViewModelFactory {
    public enum Mode {
        /// The real API, with data saved on the device.
        case live
        /// The offline sample catalog, with nothing saved. Launch with `-demo`.
        case demo
    }

    public let settings: AppSettingsModel
    public let favorites: FavoritesLibrary
    public let watchHistory: WatchHistoryLibrary

    private let fetchCatalogPage: FetchCatalogPageUseCase
    private let fetchGenres: FetchGenresUseCase
    private let searchTitles: SearchTitlesUseCase
    private let fetchCountries: FetchCountriesUseCase
    private let fetchSeasons: FetchSeasonsUseCase
    private let playback: PlaybackCoordinator

    /// The mode for this launch: `.demo` when started with `-demo`.
    public static func makeDefault(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppContainer {
        AppContainer(mode: arguments.contains("-demo") ? .demo : .live)
    }

    public init(mode: Mode) {
        Vazirmatn.register()

        // Data layer
        let catalog: any CatalogRepository
        let seasons: any SeasonRepository
        let search: any SearchRepository
        let genres: any GenreRepository
        let countries: any CountryRepository
        let storage: any KeyValueStorage

        switch mode {
        case .live:
            let client = APIClient(
                configuration: .live,
                http: URLSessionHTTPClient(timeout: APIConfiguration.live.timeout)
            )
            catalog = RemoteCatalogRepository(client: client)
            seasons = RemoteSeasonRepository(client: client)
            search = RemoteSearchRepository(client: client)
            genres = RemoteGenreRepository(client: client)
            countries = RemoteCountryRepository(client: client)
            storage = Self.deviceStorage()
        case .demo:
            catalog = DemoCatalogRepository()
            seasons = DemoSeasonRepository()
            search = DemoSearchRepository()
            genres = DemoGenreRepository()
            countries = DemoCountryRepository()
            storage = InMemoryStorage()
        }

        // Domain
        let policy = TitleContentPolicy()
        fetchCatalogPage = FetchCatalogPageUseCase(repository: catalog, policy: policy)
        fetchGenres = FetchGenresUseCase(repository: genres)
        searchTitles = SearchTitlesUseCase(repository: search, policy: policy)
        fetchCountries = FetchCountriesUseCase(repository: countries)
        fetchSeasons = FetchSeasonsUseCase(repository: seasons)

        // App-wide state
        settings = AppSettingsModel(useCase: SettingsUseCase(repository: LocalSettingsRepository(storage: storage)))
        favorites = FavoritesLibrary(useCase: FavoritesUseCase(repository: LocalFavoritesRepository(storage: storage)))
        watchHistory = WatchHistoryLibrary(useCase: WatchHistoryUseCase(repository: LocalWatchHistoryRepository(storage: storage)))

        // Player
        playback = PlaybackCoordinator(settings: settings, watchHistory: watchHistory)
    }

    /// tvOS may purge app files at any time, so everything small goes to UserDefaults there.
    private static func deviceStorage() -> any KeyValueStorage {
        #if os(tvOS)
        UserDefaultsStorage()
        #else
        FileStorage.applicationSupport(folderName: "CCloud")
        #endif
    }

    /// Loads the saved settings, favorites and watch history.
    public func bootstrap() async {
        async let settingsLoaded: Void = settings.load()
        async let favoritesLoaded: Void = favorites.load()
        async let historyLoaded: Void = watchHistory.load()
        _ = await (settingsLoaded, favoritesLoaded, historyLoaded)
    }

    // MARK: ViewModelFactory

    public func makeCatalogViewModel(feed: CatalogFeed) -> CatalogViewModel {
        CatalogViewModel(feed: feed, fetchPage: fetchCatalogPage, fetchGenres: fetchGenres)
    }

    public func makeSearchViewModel() -> SearchViewModel {
        #if os(tvOS)
        // The tvOS keyboard has no search key, so results follow the typing.
        SearchViewModel(search: searchTitles, fetchCountries: fetchCountries, liveSearchDelay: .milliseconds(700))
        #else
        SearchViewModel(search: searchTitles, fetchCountries: fetchCountries)
        #endif
    }

    public func makeDetailViewModel(item: MediaItem) -> MediaDetailViewModel {
        MediaDetailViewModel(
            item: item,
            favorites: favorites,
            watchHistory: watchHistory,
            fetchSeasons: fetchSeasons,
            playback: playback
        )
    }

    public func makeFavoritesViewModel() -> FavoritesViewModel {
        FavoritesViewModel(library: favorites)
    }

    public func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(model: settings, watchHistory: watchHistory)
    }
}
