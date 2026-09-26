import Foundation

/// Where the catalog API lives.
public struct APIConfiguration: Sendable {
    /// Tried first for every request.
    public let primaryHost: URL
    /// Tried in order, with the same path, when the primary host fails.
    public let fallbackHosts: [URL]
    /// Sent as a path segment of every request.
    public let apiKey: String
    public let timeout: TimeInterval

    public init(primaryHost: URL, fallbackHosts: [URL], apiKey: String, timeout: TimeInterval = 30) {
        self.primaryHost = primaryHost
        self.fallbackHosts = fallbackHosts
        self.apiKey = apiKey
        self.timeout = timeout
    }

    /// The servers and key the Android app uses.
    public static let live = APIConfiguration(
        primaryHost: URL(string: "https://server-hi-speed-iran.info")!,
        fallbackHosts: [
            URL(string: "https://hostinnegar.com")!,
            URL(string: "https://windowsdiba.info")!,
        ],
        apiKey: "4F5A9C3D9A86FA54EACEDDD635185"
    )
}
