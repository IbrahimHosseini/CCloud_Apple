import Foundation

// Ports implemented by the data layer. The domain only knows these protocols.

/// Paginated lists of titles.
public protocol CatalogRepository: Sendable {
    /// One page of `feed`. Page indexes start at 0. An empty result means there are no more pages.
    func page(_ feed: CatalogFeed, sortedBy order: CatalogSortOrder, index: Int) async throws -> [MediaItem]
}

public protocol SeasonRepository: Sendable {
    func seasons(ofSeries seriesID: Int) async throws -> [Season]
}

public protocol SearchRepository: Sendable {
    func search(_ query: String) async throws -> [MediaItem]
}

public protocol GenreRepository: Sendable {
    func genres() async throws -> [Genre]
}

public protocol CountryRepository: Sendable {
    func countries() async throws -> [Country]
}

public protocol FavoritesRepository: Sendable {
    func load() async throws -> FavoritesBook
    func save(_ book: FavoritesBook) async throws
}

public protocol WatchHistoryRepository: Sendable {
    func load() async throws -> WatchHistory
    func save(_ history: WatchHistory) async throws
    /// Bytes the stored history takes up.
    func storageSize() async -> Int
}

public protocol SettingsRepository: Sendable {
    /// The saved settings, or the defaults when nothing is saved or it can't be read.
    func load() async -> AppSettings
    func save(_ settings: AppSettings) async throws
}
