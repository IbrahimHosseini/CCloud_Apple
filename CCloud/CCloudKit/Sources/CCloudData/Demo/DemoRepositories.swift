import CCloudDomain
import Foundation

/// An offline catalog of fictional titles, for previews, UI tests and trying the app
/// without the API (launch with `-demo`). Ratings and years are sample values.
public enum DemoCatalog {
    /// Apple's public HLS test stream, so demo titles are playable.
    static let streamURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8")!

    public static let genres: [Genre] = [
        Genre(id: 1, title: "Action"),
        Genre(id: 2, title: "Animation"),
        Genre(id: 3, title: "Comedy"),
        Genre(id: 4, title: "Documentary"),
        Genre(id: 5, title: "Drama"),
        Genre(id: 6, title: "Sci-Fi"),
    ]

    public static let countries: [Country] = [
        Country(id: 1, title: "United States", imageURL: nil),
        Country(id: 2, title: "United Kingdom", imageURL: nil),
        Country(id: 3, title: "France", imageURL: nil),
        Country(id: 4, title: "Japan", imageURL: nil),
        Country(id: 5, title: "South Korea", imageURL: nil),
        Country(id: 6, title: "Iran", imageURL: nil),
    ]

    private static let adjectives = ["Silent", "Last", "Hidden", "Golden", "Northern", "Distant", "Paper", "Crimson", "Electric", "Frozen", "Wild", "Midnight"]
    private static let nouns = ["Garden", "Lighthouse", "Horizon", "River", "Kingdom", "Signal", "Harbor", "Echo", "Voyage", "Empire"]

    /// Deterministic fictional titles of one kind, `perPage` per page.
    static func items(kind: MediaKind, page: Int, perPage: Int = 18) -> [MediaItem] {
        (0..<perPage).map { offset in
            let index = page * perPage + offset
            return item(kind: kind, index: index)
        }
    }

    static func item(kind: MediaKind, index: Int) -> MediaItem {
        let seed = kind == .movie ? index : index + 7
        let title = "The \(adjectives[seed % adjectives.count]) \(nouns[(seed / adjectives.count + seed) % nouns.count])"
        let genre = genres[seed % genres.count]
        let secondGenre = genres[(seed + 2) % genres.count]
        let country = countries[seed % countries.count]
        let serverID = index + 1
        return MediaItem(
            serverID: serverID,
            kind: kind,
            title: kind == .movie ? title : "\(title) Chronicles",
            overview: "A sample \(kind == .movie ? "movie" : "series") from the offline demo catalog. "
                + "It has no real artwork, so the app draws a placeholder in its place.",
            year: 2026 - (seed % 15),
            imdbRating: Double(55 + (seed * 7) % 40) / 10,
            rating: Double(30 + (seed * 3) % 20) / 10,
            duration: kind == .movie ? "\(85 + (seed * 11) % 60) min" : nil,
            posterURL: nil,
            coverURL: nil,
            genres: [genre, secondGenre],
            countries: [country],
            sources: kind == .movie ? [
                MediaSource(id: serverID * 10 + 1, quality: "1080p", format: "m3u8", url: streamURL),
                MediaSource(id: serverID * 10 + 2, quality: "720p", format: "m3u8", url: streamURL),
            ] : []
        )
    }
}

/// Simulated network latency so loading states are visible.
private func demoDelay() async throws {
    try await Task.sleep(for: .milliseconds(350))
}

public struct DemoCatalogRepository: CatalogRepository {
    /// Pages after this one are empty.
    let lastPage = 2

    public init() {}

    public func page(_ feed: CatalogFeed, sortedBy order: CatalogSortOrder, index: Int) async throws -> [MediaItem] {
        try await demoDelay()
        guard index <= lastPage else { return [] }
        let items: [MediaItem] = switch feed {
        case .movies(let genreID):
            DemoCatalog.items(kind: .movie, page: index).filter { genreID == nil || $0.genres.contains { $0.id == genreID } }
        case .series(let genreID):
            DemoCatalog.items(kind: .series, page: index).filter { genreID == nil || $0.genres.contains { $0.id == genreID } }
        case .country(let countryID):
            (DemoCatalog.items(kind: .movie, page: index) + DemoCatalog.items(kind: .series, page: index))
                .filter { $0.countries.contains { $0.id == countryID } }
        }
        switch order {
        case .recentlyAdded: return items
        case .releaseYear: return items.sorted { ($0.year ?? 0) > ($1.year ?? 0) }
        case .imdbRating: return items.sorted { ($0.imdbRating ?? 0) > ($1.imdbRating ?? 0) }
        }
    }
}

public struct DemoSeasonRepository: SeasonRepository {
    public init() {}

    public func seasons(ofSeries seriesID: Int) async throws -> [Season] {
        try await demoDelay()
        return (1...3).map { seasonNumber in
            let seasonID = seriesID * 100 + seasonNumber
            return Season(
                id: seasonID,
                number: seasonNumber,
                title: "Season \(seasonNumber)",
                episodes: (1...8).map { episodeNumber in
                    let episodeID = seasonID * 100 + episodeNumber
                    return Episode(
                        id: episodeID,
                        number: episodeNumber,
                        title: "Chapter \(episodeNumber)",
                        overview: "Episode \(episodeNumber) of season \(seasonNumber).",
                        duration: "\(40 + episodeNumber) min",
                        imageURL: nil,
                        sources: [
                            MediaSource(id: episodeID * 10 + 1, quality: "1080p", format: "m3u8", url: DemoCatalog.streamURL),
                            MediaSource(id: episodeID * 10 + 2, quality: "480p", format: "m3u8", url: DemoCatalog.streamURL),
                        ]
                    )
                }
            )
        }
    }
}

public struct DemoSearchRepository: SearchRepository {
    public init() {}

    public func search(_ query: String) async throws -> [MediaItem] {
        try await demoDelay()
        let all = (0...1).flatMap { DemoCatalog.items(kind: .movie, page: $0) + DemoCatalog.items(kind: .series, page: $0) }
        return all.filter { $0.title.localizedStandardContains(query) }
    }
}

public struct DemoGenreRepository: GenreRepository {
    public init() {}

    public func genres() async throws -> [Genre] {
        try await demoDelay()
        return DemoCatalog.genres
    }
}

public struct DemoCountryRepository: CountryRepository {
    public init() {}

    public func countries() async throws -> [Country] {
        try await demoDelay()
        return DemoCatalog.countries
    }
}
