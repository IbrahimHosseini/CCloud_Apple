import Foundation

public struct WatchedEpisode: Hashable, Codable, Sendable {
    public let episode: EpisodeReference
    public let watchedAt: Date

    public init(episode: EpisodeReference, watchedAt: Date) {
        self.episode = episode
        self.watchedAt = watchedAt
    }
}

/// Which episodes the user has started watching. A value type with no I/O.
public struct WatchHistory: Hashable, Sendable {
    private var watched: [EpisodeReference: Date]

    public init(_ episodes: [WatchedEpisode] = []) {
        watched = Dictionary(episodes.map { ($0.episode, $0.watchedAt) }, uniquingKeysWith: max)
    }

    public static let empty = WatchHistory()

    public var episodes: [WatchedEpisode] {
        watched
            .map { WatchedEpisode(episode: $0.key, watchedAt: $0.value) }
            .sorted { $0.watchedAt > $1.watchedAt }
    }

    public var count: Int { watched.count }

    public func isWatched(_ episode: EpisodeReference) -> Bool {
        watched[episode] != nil
    }

    public mutating func markWatched(_ episode: EpisodeReference, at date: Date) {
        watched[episode] = date
    }

    public mutating func markUnwatched(_ episode: EpisodeReference) {
        watched[episode] = nil
    }

    public mutating func removeAll() {
        watched.removeAll()
    }
}
