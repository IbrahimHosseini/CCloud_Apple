import CCloudDomain
import Foundation

// DTO → domain entity mapping. Items that can't be used (no id, no playable URL) are dropped.

extension PosterDTO {
    /// Maps to a domain item. `kind` overrides the item's own type field, for endpoints
    /// that only return one kind. Returns `nil` for unknown types or missing ids.
    func toDomain(kind forcedKind: MediaKind? = nil) -> MediaItem? {
        guard id > 0, let kind = forcedKind ?? Self.kind(from: type) else { return nil }
        return MediaItem(
            serverID: id,
            kind: kind,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            overview: description.trimmingCharacters(in: .whitespacesAndNewlines),
            year: year > 0 ? year : nil,
            imdbRating: imdb > 0 ? imdb : nil,
            rating: rating > 0 ? rating : nil,
            duration: Self.cleanDuration(duration),
            posterURL: URL.lenient(image),
            coverURL: URL.lenient(cover),
            genres: genres.compactMap { $0.toDomain() },
            countries: country.compactMap { $0.toDomain() },
            sources: kind == .movie ? sources.compactMap { $0.toDomain() } : []
        )
    }

    static func kind(from type: String) -> MediaKind? {
        switch type.lowercased() {
        case "movie": .movie
        case "serie", "series": .series
        default: nil
        }
    }

    /// The API uses "null" and "N/A" for unknown durations.
    static func cleanDuration(_ duration: String?) -> String? {
        guard let duration = duration?.trimmingCharacters(in: .whitespacesAndNewlines),
              !duration.isEmpty,
              duration.lowercased() != "null",
              duration.uppercased() != "N/A"
        else { return nil }
        return duration
    }
}

extension GenreDTO {
    func toDomain() -> Genre? {
        guard id > 0 else { return nil }
        return Genre(id: id, title: title)
    }
}

extension CountryDTO {
    func toDomain() -> Country? {
        guard id > 0 else { return nil }
        return Country(id: id, title: title, imageURL: URL.lenient(image))
    }
}

extension SourceDTO {
    func toDomain() -> MediaSource? {
        guard let url = URL.lenient(url) else { return nil }
        return MediaSource(id: id, quality: quality, format: type, url: url)
    }
}

extension SeasonDTO {
    /// `position` is the 1-based index within the series.
    func toDomain(position: Int) -> Season {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return Season(
            id: id,
            number: position,
            title: title.lowercased() == "null" ? "" : title,
            episodes: episodes.enumerated().map { index, episode in episode.toDomain(position: index + 1) }
        )
    }
}

extension EpisodeDTO {
    /// `position` is the 1-based index within the season.
    func toDomain(position: Int) -> Episode {
        let title = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return Episode(
            id: id,
            number: position,
            title: title.lowercased() == "null" ? "" : title,
            overview: description,
            duration: PosterDTO.cleanDuration(duration),
            imageURL: URL.lenient(image),
            sources: sources.compactMap { $0.toDomain() }
        )
    }
}

extension URL {
    /// A web URL from loosely formatted API text, or `nil` if there's nothing usable.
    static func lenient(_ string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.lowercased() != "null" else { return nil }
        // URL(string:) percent-encodes spaces and other invalid characters itself.
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https", url.host() != nil
        else { return nil }
        return url
    }
}
