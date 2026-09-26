@testable import CCloudData
import CCloudDomain
import Foundation
import Testing

/// Answers requests per host, and records the order they were made in.
private final class ScriptedHTTPClient: HTTPClient, @unchecked Sendable {
    enum Reply {
        case status(Int, String)
        case failure(URLError.Code)
    }

    private let lock = NSLock()
    private var _requestedHosts: [String] = []
    private let replies: [String: Reply]

    init(_ replies: [String: Reply]) {
        self.replies = replies
    }

    var requestedHosts: [String] { lock.withLock { _requestedHosts } }

    func data(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let host = url.host() ?? ""
        lock.withLock { _requestedHosts.append(host) }
        switch replies[host] ?? .failure(.cannotFindHost) {
        case .status(let code, let body):
            return (Data(body.utf8), HTTPURLResponse(url: url, statusCode: code, httpVersion: nil, headerFields: nil)!)
        case .failure(let code):
            throw URLError(code)
        }
    }
}

@Suite("API client")
struct APIClientTests {
    let configuration = APIConfiguration(
        primaryHost: URL(string: "https://primary.example")!,
        fallbackHosts: [URL(string: "https://helper1.example")!, URL(string: "https://helper2.example")!],
        apiKey: "KEY"
    )

    @Test func usesThePrimaryHostWhenItWorks() async throws {
        let http = ScriptedHTTPClient(["primary.example": .status(200, "[]")])
        let client = APIClient(configuration: configuration, http: http)

        _ = try await client.data(for: .genres)
        #expect(http.requestedHosts == ["primary.example"])
    }

    @Test func fallsBackToHelperHostsInOrder() async throws {
        let http = ScriptedHTTPClient([
            "primary.example": .failure(.timedOut),
            "helper1.example": .status(503, ""),
            "helper2.example": .status(200, #"[{"id": 1, "title": "Drama"}]"#),
        ])
        let repository = RemoteGenreRepository(client: APIClient(configuration: configuration, http: http))

        let genres = try await repository.genres()
        #expect(genres == [Genre(id: 1, title: "Drama")])
        #expect(http.requestedHosts == ["primary.example", "helper1.example", "helper2.example"])
    }

    @Test func reportsWhyThePrimaryHostFailed() async {
        let http = ScriptedHTTPClient([
            "primary.example": .failure(.notConnectedToInternet),
            "helper1.example": .status(500, ""),
            "helper2.example": .status(500, ""),
        ])
        let client = APIClient(configuration: configuration, http: http)

        await #expect(throws: DomainError.offline) {
            try await client.data(for: .countries)
        }
    }

    @Test func mapsHTTPAndDecodingFailures() async {
        let serverError = APIClient(configuration: APIConfiguration(primaryHost: configuration.primaryHost, fallbackHosts: [], apiKey: "KEY"),
                                    http: ScriptedHTTPClient(["primary.example": .status(404, "")]))
        await #expect(throws: DomainError.server(statusCode: 404)) {
            try await serverError.data(for: .genres)
        }

        let badJSON = APIClient(configuration: configuration, http: ScriptedHTTPClient(["primary.example": .status(200, "<html>")]))
        await #expect(throws: DomainError.invalidResponse) {
            try await RemoteSearchRepository(client: badJSON).search("x")
        }
    }

    @Test func unreachableHostsAreNotReportedAsOffline() {
        #expect(APIClient.domainError(from: URLError(.cannotFindHost)) == .serverUnreachable)
        #expect(APIClient.domainError(from: URLError(.notConnectedToInternet)) == .offline)
        #expect(APIClient.domainError(from: URLError(.timedOut)) == .timedOut)
    }
}
