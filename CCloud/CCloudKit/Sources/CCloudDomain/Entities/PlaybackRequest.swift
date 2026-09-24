import Foundation

/// Everything a player needs to start playing one source.
public struct PlaybackRequest: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    /// The movie or series title.
    public let title: String
    public let source: MediaSource
    public let artworkURL: URL?
    /// Set when playing an episode.
    public let episode: EpisodeContext?

    public init(id: UUID = UUID(), title: String, source: MediaSource, artworkURL: URL? = nil, episode: EpisodeContext? = nil) {
        self.id = id
        self.title = title
        self.source = source
        self.artworkURL = artworkURL
        self.episode = episode
    }

    /// The same request playing `source` instead, e.g. after switching the quality.
    public func with(source: MediaSource) -> PlaybackRequest {
        PlaybackRequest(id: id, title: title, source: source, artworkURL: artworkURL, episode: episode)
    }
}

/// Which episode a playback request belongs to.
public struct EpisodeContext: Hashable, Codable, Sendable {
    public let reference: EpisodeReference
    public let seasonNumber: Int
    public let episodeNumber: Int
    /// Empty when the episode has no title.
    public let episodeTitle: String

    public init(reference: EpisodeReference, seasonNumber: Int, episodeNumber: Int, episodeTitle: String) {
        self.reference = reference
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.episodeTitle = episodeTitle
    }
}
