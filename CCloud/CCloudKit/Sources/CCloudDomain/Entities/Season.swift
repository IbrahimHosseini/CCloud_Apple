import Foundation

public struct Season: Identifiable, Hashable, Codable, Sendable {
    public let id: Int
    /// 1-based position within the series.
    public let number: Int
    /// Empty when the server has no title for it.
    public let title: String
    public let episodes: [Episode]

    public init(id: Int, number: Int, title: String, episodes: [Episode]) {
        self.id = id
        self.number = number
        self.title = title
        self.episodes = episodes
    }
}

public struct Episode: Identifiable, Hashable, Codable, Sendable {
    public let id: Int
    /// 1-based position within its season.
    public let number: Int
    /// Empty when the server has no title for it.
    public let title: String
    public let overview: String
    public let duration: String?
    public let imageURL: URL?
    public let sources: [MediaSource]

    public init(id: Int, number: Int, title: String, overview: String, duration: String?, imageURL: URL?, sources: [MediaSource]) {
        self.id = id
        self.number = number
        self.title = title
        self.overview = overview
        self.duration = duration
        self.imageURL = imageURL
        self.sources = sources
    }
}

/// Identifies one episode of one season of one series, e.g. to mark it as watched.
public struct EpisodeReference: Hashable, Codable, Sendable {
    public let seriesID: Int
    public let seasonID: Int
    public let episodeID: Int

    public init(seriesID: Int, seasonID: Int, episodeID: Int) {
        self.seriesID = seriesID
        self.seasonID = seasonID
        self.episodeID = episodeID
    }
}
