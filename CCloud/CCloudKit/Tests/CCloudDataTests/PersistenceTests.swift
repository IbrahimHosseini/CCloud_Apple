@testable import CCloudData
import CCloudDomain
import Foundation
import Testing

@Suite("Local persistence")
struct PersistenceTests {
    let item = MediaItem(
        serverID: 5,
        kind: .movie,
        title: "Heat",
        overview: "LA crime saga",
        year: 1995,
        imdbRating: 8.3,
        rating: nil,
        duration: "170 min",
        posterURL: URL(string: "https://img.example.com/heat.jpg"),
        coverURL: nil,
        genres: [Genre(id: 1, title: "Crime")],
        countries: [Country(id: 2, title: "USA", imageURL: nil)],
        sources: [MediaSource(id: 1, quality: "1080p", format: "mkv", url: URL(string: "https://cdn.example.com/heat.mkv")!)]
    )

    @Test func favoritesAndPlaylistsRoundTrip() async throws {
        let repository = LocalFavoritesRepository(storage: InMemoryStorage())
        var book = FavoritesBook()
        book.add(item, at: Date(timeIntervalSince1970: 1_700_000_000))
        let playlist = try book.createPlaylist(named: "Classics")
        book.setMembership(of: item.id, to: [playlist.id])

        try await repository.save(book)
        let loaded = try await repository.load()

        #expect(loaded == book)
        // A movie keeps its sources, so it stays playable from Favorites.
        #expect(loaded.entries.first?.item.sources.count == 1)
    }

    @Test func missingDataLoadsAsEmpty() async throws {
        let storage = InMemoryStorage()
        #expect(try await LocalFavoritesRepository(storage: storage).load() == .empty)
        #expect(try await LocalWatchHistoryRepository(storage: storage).load() == .empty)
        #expect(await LocalSettingsRepository(storage: storage).load() == .default)
    }

    @Test func unreadableSettingsFallBackToDefaults() async throws {
        let storage = InMemoryStorage()
        await storage.setData(Data("not json".utf8), forKey: "settings.v1")
        #expect(await LocalSettingsRepository(storage: storage).load() == .default)
    }

    @Test func watchHistoryRoundTripsAndReportsItsSize() async throws {
        let repository = LocalWatchHistoryRepository(storage: InMemoryStorage())
        var history = WatchHistory()
        history.markWatched(EpisodeReference(seriesID: 1, seasonID: 2, episodeID: 3), at: Date(timeIntervalSince1970: 50))

        try await repository.save(history)
        #expect(try await repository.load() == history)
        #expect(await repository.storageSize() > 0)

        try await repository.save(WatchHistory())
        #expect(await repository.storageSize() == 0)
    }

    @Test func fileStorageWritesReadsAndDeletes() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "ccloud-tests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let storage = FileStorage(directory: directory)

        try await storage.setData(Data("hello".utf8), forKey: "greeting")
        #expect(try await storage.data(forKey: "greeting") == Data("hello".utf8))

        try await storage.setData(nil, forKey: "greeting")
        #expect(try await storage.data(forKey: "greeting") == nil)
    }
}
