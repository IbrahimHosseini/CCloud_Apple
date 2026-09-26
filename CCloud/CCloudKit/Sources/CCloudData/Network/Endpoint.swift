import CCloudDomain
import Foundation

/// The catalog API's endpoints, as path segments below the host.
///
/// Segment layout and trailing slashes match what the Android app sends.
enum Endpoint: Hashable, Sendable {
    case movies(genreID: Int, sort: CatalogSortOrder, page: Int)
    case series(genreID: Int, sort: CatalogSortOrder, page: Int)
    case countryTitles(countryID: Int, sort: CatalogSortOrder, page: Int)
    case seasons(seriesID: Int)
    case search(query: String)
    case genres
    case countries

    func path(apiKey: String) -> (segments: [String], trailingSlash: Bool) {
        switch self {
        case let .movies(genreID, sort, page):
            (["api", "movie", "by", "filtres", "\(genreID)", sort.pathValue, "\(page)", apiKey], false)
        case let .series(genreID, sort, page):
            (["api", "serie", "by", "filtres", "\(genreID)", sort.pathValue, "\(page)", apiKey], false)
        case let .countryTitles(countryID, sort, page):
            (["api", "poster", "by", "filtres", "0", "\(countryID)", sort.pathValue, "\(page)", apiKey], false)
        case let .seasons(seriesID):
            (["api", "season", "by", "serie", "\(seriesID)", apiKey], true)
        case let .search(query):
            (["api", "search", query, apiKey], true)
        case .genres:
            (["api", "genre", "all", apiKey], false)
        case .countries:
            (["api", "country", "all", apiKey], true)
        }
    }

    func url(host: URL, apiKey: String) -> URL? {
        let (segments, trailingSlash) = path(apiKey: apiKey)
        let encoded = segments.map { $0.addingPercentEncoding(withAllowedCharacters: .pathSegmentAllowed) ?? $0 }
        let base = host.absoluteString.hasSuffix("/") ? String(host.absoluteString.dropLast()) : host.absoluteString
        return URL(string: base + "/" + encoded.joined(separator: "/") + (trailingSlash ? "/" : ""))
    }
}

private extension CatalogSortOrder {
    var pathValue: String {
        switch self {
        case .recentlyAdded: "created"
        case .releaseYear: "year"
        case .imdbRating: "imdb"
        }
    }
}

private extension CharacterSet {
    /// RFC 3986 unreserved characters. Everything else in a path segment gets percent-encoded,
    /// including "/" and "?" typed into a search query.
    static let pathSegmentAllowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
}
