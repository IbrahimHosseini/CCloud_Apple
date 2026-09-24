import Foundation

/// Failures the presentation layer knows how to explain to the user.
public enum DomainError: Error, Hashable, Sendable {
    /// No network connection.
    case offline
    /// The device is online but none of the servers could be reached.
    case serverUnreachable
    /// The server didn't answer in time.
    case timedOut
    /// The server answered with a non-success HTTP status.
    case server(statusCode: Int)
    /// The server answered with something that isn't the expected JSON.
    case invalidResponse
    /// Anything else, with a description for logs.
    case unknown(String)
}

public enum PlaylistError: Error, Hashable, Sendable {
    /// The name is empty or whitespace only.
    case emptyName
    /// Another playlist already has this name (case-insensitive).
    case duplicateName
    /// The playlist doesn't exist (anymore).
    case notFound
}
