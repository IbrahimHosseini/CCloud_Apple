import Foundation

/// The two kinds of titles the catalog serves.
public enum MediaKind: String, Codable, Hashable, Sendable, CaseIterable {
    case movie
    case series
}

/// Movies and series have independent id spaces on the server, so identity needs both.
public struct MediaID: Hashable, Codable, Sendable, CustomStringConvertible {
    public let kind: MediaKind
    public let value: Int

    public init(kind: MediaKind, value: Int) {
        self.kind = kind
        self.value = value
    }

    public var description: String { "\(kind.rawValue)-\(value)" }
}

public struct Genre: Identifiable, Hashable, Codable, Sendable {
    public let id: Int
    public let title: String

    public init(id: Int, title: String) {
        self.id = id
        self.title = title
    }
}

public struct Country: Identifiable, Hashable, Codable, Sendable {
    public let id: Int
    public let title: String
    public let imageURL: URL?

    public init(id: Int, title: String, imageURL: URL?) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
    }
}

/// One playable file of a movie or episode, usually one per quality (e.g. "1080p").
public struct MediaSource: Identifiable, Hashable, Codable, Sendable {
    public let id: Int
    public let quality: String
    /// The server's format label (e.g. "mp4", "mkv"). Informational only.
    public let format: String
    public let url: URL

    public init(id: Int, quality: String, format: String, url: URL) {
        self.id = id
        self.quality = quality
        self.format = format
        self.url = url
    }

    /// Lowercased file extension of the URL path, e.g. "mkv". Empty when there is none.
    public var fileExtension: String { url.pathExtension.lowercased() }
}

/// A movie or a series as listed by the catalog.
///
/// There is no "get title by id" endpoint, so a list item carries everything the detail
/// screen needs, including the playable sources of a movie.
public struct MediaItem: Identifiable, Hashable, Codable, Sendable {
    public let serverID: Int
    public let kind: MediaKind
    public let title: String
    public let overview: String
    public let year: Int?
    public let imdbRating: Double?
    public let rating: Double?
    public let duration: String?
    public let posterURL: URL?
    public let coverURL: URL?
    public let genres: [Genre]
    public let countries: [Country]
    /// Playable files. Always empty for series: episodes carry their own sources.
    public let sources: [MediaSource]

    public init(
        serverID: Int,
        kind: MediaKind,
        title: String,
        overview: String,
        year: Int?,
        imdbRating: Double?,
        rating: Double?,
        duration: String?,
        posterURL: URL?,
        coverURL: URL?,
        genres: [Genre],
        countries: [Country],
        sources: [MediaSource]
    ) {
        self.serverID = serverID
        self.kind = kind
        self.title = title
        self.overview = overview
        self.year = year
        self.imdbRating = imdbRating
        self.rating = rating
        self.duration = duration
        self.posterURL = posterURL
        self.coverURL = coverURL
        self.genres = genres
        self.countries = countries
        self.sources = sources
    }

    public var id: MediaID { MediaID(kind: kind, value: serverID) }

    /// The wide artwork for headers, falling back to the poster.
    public var backdropURL: URL? { coverURL ?? posterURL }
}
