import CCloudDomain
import Foundation

enum StorageKey {
    static let favorites = "favorites.v1"
    static let watchHistory = "watch-history.v1"
    static let settings = "settings.v1"
}

extension JSONEncoder {
    static var storage: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    static var storage: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

public struct LocalFavoritesRepository: FavoritesRepository {
    private let storage: any KeyValueStorage

    public init(storage: any KeyValueStorage) {
        self.storage = storage
    }

    public func load() async throws -> FavoritesBook {
        guard let data = try await storage.data(forKey: StorageKey.favorites) else { return .empty }
        let snapshot = try JSONDecoder.storage.decode(Snapshot.self, from: data)
        return FavoritesBook(entries: snapshot.entries, playlists: snapshot.playlists)
    }

    public func save(_ book: FavoritesBook) async throws {
        let data = try JSONEncoder.storage.encode(Snapshot(entries: book.entries, playlists: book.playlists))
        try await storage.setData(data, forKey: StorageKey.favorites)
    }

    private struct Snapshot: Codable {
        let entries: [FavoriteEntry]
        let playlists: [Playlist]
    }
}

public struct LocalWatchHistoryRepository: WatchHistoryRepository {
    private let storage: any KeyValueStorage

    public init(storage: any KeyValueStorage) {
        self.storage = storage
    }

    public func load() async throws -> WatchHistory {
        guard let data = try await storage.data(forKey: StorageKey.watchHistory) else { return .empty }
        return WatchHistory(try JSONDecoder.storage.decode([WatchedEpisode].self, from: data))
    }

    public func save(_ history: WatchHistory) async throws {
        let data = history.count == 0 ? nil : try JSONEncoder.storage.encode(history.episodes)
        try await storage.setData(data, forKey: StorageKey.watchHistory)
    }

    public func storageSize() async -> Int {
        (try? await storage.data(forKey: StorageKey.watchHistory))?.count ?? 0
    }
}

public struct LocalSettingsRepository: SettingsRepository {
    private let storage: any KeyValueStorage

    public init(storage: any KeyValueStorage) {
        self.storage = storage
    }

    public func load() async -> AppSettings {
        guard let data = try? await storage.data(forKey: StorageKey.settings),
              let settings = try? JSONDecoder.storage.decode(AppSettings.self, from: data)
        else { return .default }
        return settings
    }

    public func save(_ settings: AppSettings) async throws {
        try await storage.setData(JSONEncoder.storage.encode(settings), forKey: StorageKey.settings)
    }
}
