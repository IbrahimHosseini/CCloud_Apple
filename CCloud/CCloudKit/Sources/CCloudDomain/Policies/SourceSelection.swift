import Foundation

// The catalog lists trailers as sources ("تیزر", "Trailer") and as the first "episode" of
// a season. These rules keep the Play buttons on the real thing.

enum TrailerMarkers {
    static let words = ["تیزر", "تریلر", "trailer", "teaser"]

    static func matches(_ text: String) -> Bool {
        let text = text.lowercased()
        return words.contains { text.contains($0) }
    }
}

public extension MediaSource {
    /// Whether this file is a trailer rather than the title itself.
    var isTrailer: Bool { TrailerMarkers.matches(quality) }

    /// Vertical resolution named in the quality label ("1080", "720p", "4K"), if any.
    var resolution: Int? {
        let label = quality.lowercased()
        if label.contains("4k") || label.contains("uhd") { return 2160 }
        let numbers = label
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }
            .filter { (144...4320).contains($0) }
        return numbers.max()
    }
}

public extension Array where Element == MediaSource {
    /// The source a plain "Play" should start: the highest-resolution one that isn't a
    /// trailer, else the first non-trailer, else the first.
    var preferredForPlayback: MediaSource? {
        let features = filter { !$0.isTrailer }
        let candidates = features.isEmpty ? self : features
        return candidates.enumerated().max { lhs, rhs in
            let left = lhs.element.resolution ?? 0, right = rhs.element.resolution ?? 0
            // On equal resolution keep the earlier source.
            return left == right ? lhs.offset > rhs.offset : left < right
        }?.element
    }
}

public extension Episode {
    /// Whether this "episode" is a trailer for the season.
    var isTrailer: Bool {
        TrailerMarkers.matches(title) || (!sources.isEmpty && sources.allSatisfy(\.isTrailer))
    }
}
