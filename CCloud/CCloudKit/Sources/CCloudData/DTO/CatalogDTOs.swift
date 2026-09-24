import Foundation

// Wire formats of the catalog API. Defaults mirror the Android app's parser.

/// A movie, series or mixed-list item ("poster" in the API).
struct PosterDTO: Decodable {
    let id: Int
    let type: String
    let title: String
    let description: String
    let year: Int
    let imdb: Double
    let rating: Double
    let duration: String?
    let image: String
    let cover: String
    let genres: [GenreDTO]
    let sources: [SourceDTO]
    let country: [CountryDTO]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = container.lenientInt("id") ?? 0
        type = container.lenientString("type") ?? ""
        title = container.lenientString("title") ?? ""
        description = container.lenientString("description") ?? ""
        year = container.lenientInt("year") ?? 0
        imdb = container.lenientDouble("imdb") ?? 0
        rating = container.lenientDouble("rating") ?? 0
        duration = container.lenientString("duration")
        image = container.lenientString("image") ?? ""
        cover = container.lenientString("cover") ?? ""
        genres = container.lossyArray("genres")
        sources = container.lossyArray("sources")
        country = container.lossyArray("country")
    }
}

struct GenreDTO: Decodable {
    let id: Int
    let title: String

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = container.lenientInt("id") ?? 0
        title = container.lenientString("title") ?? "Unknown"
    }
}

struct CountryDTO: Decodable {
    let id: Int
    let title: String
    let image: String

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = container.lenientInt("id") ?? 0
        title = container.lenientString("title") ?? "Unknown"
        image = container.lenientString("image") ?? ""
    }
}

struct SourceDTO: Decodable {
    let id: Int
    let quality: String
    let type: String
    let url: String

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = container.lenientInt("id") ?? 0
        quality = container.lenientString("quality") ?? "Unknown"
        type = container.lenientString("type") ?? "Unknown"
        url = container.lenientString("url") ?? ""
    }
}

struct SeasonDTO: Decodable {
    let id: Int
    let title: String
    let episodes: [EpisodeDTO]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = container.lenientInt("id") ?? 0
        title = container.lenientString("title") ?? ""
        episodes = container.lossyArray("episodes")
    }
}

struct EpisodeDTO: Decodable {
    let id: Int
    /// `nil` when missing; the mapper numbers untitled episodes.
    let title: String?
    let description: String
    let duration: String?
    let image: String
    let sources: [SourceDTO]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        id = container.lenientInt("id") ?? 0
        title = container.lenientString("title")
        description = container.lenientString("description") ?? ""
        duration = container.lenientString("duration")
        image = container.lenientString("image") ?? ""
        sources = container.lossyArray("sources")
    }
}

struct SearchResponseDTO: Decodable {
    let posters: [PosterDTO]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        guard container.contains(AnyCodingKey("posters")) else {
            throw DecodingError.keyNotFound(
                AnyCodingKey("posters"),
                .init(codingPath: decoder.codingPath, debugDescription: "Search response has no posters")
            )
        }
        posters = container.lossyArray("posters")
    }
}
