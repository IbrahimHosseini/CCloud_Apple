import CCloudDomain
@testable import CCloudPresentation
import Foundation
import Testing

extension MediaItem {
    static func fixture(id: Int, kind: MediaKind = .movie, title: String? = nil, sources: Int = 1) -> MediaItem {
        MediaItem(
            serverID: id,
            kind: kind,
            title: title ?? "Title \(id)",
            overview: "",
            year: 2020,
            imdbRating: nil,
            rating: nil,
            duration: nil,
            posterURL: nil,
            coverURL: nil,
            genres: [],
            countries: [],
            sources: (0..<sources).map { MediaSource(id: $0, quality: "\($0)p", format: "mp4", url: URL(string: "https://x.example.com/\(id)-\($0).mp4")!) }
        )
    }
}

/// Serves scripted pages and records what was requested.
final class FakeCatalogRepository: CatalogRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var pages: [Int: Result<[MediaItem], DomainError>]
    private var _requests: [(CatalogFeed, CatalogSortOrder, Int)] = []

    init(pages: [Int: Result<[MediaItem], DomainError>]) {
        self.pages = pages
    }

    var requests: [(feed: CatalogFeed, order: CatalogSortOrder, index: Int)] {
        lock.withLock { _requests.map { ($0.0, $0.1, $0.2) } }
    }

    func setPage(_ index: Int, _ result: Result<[MediaItem], DomainError>) {
        lock.withLock { pages[index] = result }
    }

    func page(_ feed: CatalogFeed, sortedBy order: CatalogSortOrder, index: Int) async throws -> [MediaItem] {
        let result = lock.withLock {
            _requests.append((feed, order, index))
            return pages[index] ?? .success([])
        }
        return try result.get()
    }
}

struct FakeGenreRepository: GenreRepository {
    func genres() async throws -> [Genre] {
        [Genre(id: 2, title: "Drama"), Genre(id: 1, title: "Action")]
    }
}

struct FakeSeasonRepository: SeasonRepository {
    var seasons: [Season]

    func seasons(ofSeries seriesID: Int) async throws -> [Season] {
        seasons
    }
}

struct FakeSearchRepository: SearchRepository {
    var results: [MediaItem]

    func search(_ query: String) async throws -> [MediaItem] {
        results.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }
}

struct FakeCountryRepository: CountryRepository {
    func countries() async throws -> [Country] {
        [Country(id: 1, title: "France", imageURL: nil)]
    }
}

actor MemoryFavoritesRepository: FavoritesRepository {
    private(set) var saved: FavoritesBook?
    func load() async throws -> FavoritesBook { saved ?? .empty }
    func save(_ book: FavoritesBook) async throws { saved = book }
}

actor MemoryWatchHistoryRepository: WatchHistoryRepository {
    private(set) var saved: WatchHistory?
    func load() async throws -> WatchHistory { saved ?? .empty }
    func save(_ history: WatchHistory) async throws { saved = history }
    func storageSize() async -> Int { saved?.count ?? 0 }
}

@MainActor
final class RecordingPlaybackLauncher: PlaybackLauncher {
    private(set) var requests: [PlaybackRequest] = []

    func play(_ request: PlaybackRequest) {
        requests.append(request)
    }
}

/// Waits for asynchronous ViewModel work to settle.
@MainActor
func waitUntil(timeout: Duration = .seconds(2), _ condition: @MainActor () -> Bool) async {
    let deadline = ContinuousClock.now + timeout
    while !condition(), ContinuousClock.now < deadline {
        try? await Task.sleep(for: .milliseconds(5))
    }
    #expect(condition(), "Timed out waiting for a condition")
}
