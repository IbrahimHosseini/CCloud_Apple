import Foundation

/// Loads and saves the favorites and playlists.
///
/// The rules for changing them live in `FavoritesBook`.
public struct FavoritesUseCase: Sendable {
    private let repository: any FavoritesRepository

    public init(repository: any FavoritesRepository) {
        self.repository = repository
    }

    /// The saved favorites, or an empty book when they can't be read.
    public func load() async -> FavoritesBook {
        (try? await repository.load()) ?? .empty
    }

    public func save(_ book: FavoritesBook) async throws {
        try await repository.save(book)
    }
}

/// Loads and saves which episodes were watched.
public struct WatchHistoryUseCase: Sendable {
    private let repository: any WatchHistoryRepository

    public init(repository: any WatchHistoryRepository) {
        self.repository = repository
    }

    /// The saved history, or an empty one when it can't be read.
    public func load() async -> WatchHistory {
        (try? await repository.load()) ?? .empty
    }

    public func save(_ history: WatchHistory) async throws {
        try await repository.save(history)
    }

    public func storageSize() async -> Int {
        await repository.storageSize()
    }
}

public struct SettingsUseCase: Sendable {
    private let repository: any SettingsRepository

    public init(repository: any SettingsRepository) {
        self.repository = repository
    }

    public func load() async -> AppSettings {
        await repository.load()
    }

    public func save(_ settings: AppSettings) async throws {
        try await repository.save(settings)
    }
}
