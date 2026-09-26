@testable import CCloudDomain
import Foundation

extension MediaItem {
    static func fixture(id: Int, kind: MediaKind = .movie, title: String? = nil) -> MediaItem {
        MediaItem(
            serverID: id,
            kind: kind,
            title: title ?? "Title \(id)",
            overview: "",
            year: 2020,
            imdbRating: 7.5,
            rating: nil,
            duration: nil,
            posterURL: nil,
            coverURL: nil,
            genres: [],
            countries: [],
            sources: []
        )
    }
}

struct StubCatalogRepository: CatalogRepository {
    var pages: [Int: [MediaItem]]

    func page(_ feed: CatalogFeed, sortedBy order: CatalogSortOrder, index: Int) async throws -> [MediaItem] {
        pages[index] ?? []
    }
}

final class CountingSearchRepository: SearchRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var _queries: [String] = []
    let results: [MediaItem]

    init(results: [MediaItem]) {
        self.results = results
    }

    var queries: [String] { lock.withLock { _queries } }

    func search(_ query: String) async throws -> [MediaItem] {
        lock.withLock { _queries.append(query) }
        return results
    }
}
