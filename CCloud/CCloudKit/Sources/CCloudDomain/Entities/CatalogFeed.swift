import Foundation

/// A paginated list of titles the catalog can serve.
public enum CatalogFeed: Hashable, Sendable {
    /// Movies, optionally narrowed to one genre.
    case movies(genreID: Int?)
    /// Series, optionally narrowed to one genre.
    case series(genreID: Int?)
    /// Movies and series produced in one country.
    case country(id: Int)

    public var genreID: Int? {
        switch self {
        case .movies(let genreID), .series(let genreID): genreID
        case .country: nil
        }
    }

    public var supportsGenreFilter: Bool {
        switch self {
        case .movies, .series: true
        case .country: false
        }
    }

    /// The same feed narrowed to `genreID`, or widened to all genres when `nil`.
    public func filtered(byGenre genreID: Int?) -> CatalogFeed {
        switch self {
        case .movies: .movies(genreID: genreID)
        case .series: .series(genreID: genreID)
        case .country: self
        }
    }
}

public enum CatalogSortOrder: String, CaseIterable, Codable, Hashable, Sendable {
    /// Most recently added to the catalog first (the server's default).
    case recentlyAdded
    /// Newest release year first.
    case releaseYear
    /// Highest IMDb rating first.
    case imdbRating
}

public struct CatalogPage: Hashable, Sendable {
    public let index: Int
    public let items: [MediaItem]
    /// `true` when the server returned nothing, i.e. there are no further pages.
    public let isLastPage: Bool

    public init(index: Int, items: [MediaItem], isLastPage: Bool) {
        self.index = index
        self.items = items
        self.isLastPage = isLastPage
    }
}
