import CCloudDomain
import Foundation

/// Performs catalog requests, falling back to the helper hosts when the primary one fails.
public struct APIClient: Sendable {
    private let configuration: APIConfiguration
    private let http: any HTTPClient

    public init(configuration: APIConfiguration, http: any HTTPClient) {
        self.configuration = configuration
        self.http = http
    }

    /// Fetches and decodes `endpoint`. Throws a `DomainError`, or `CancellationError`
    /// when the calling task was cancelled.
    func get<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type = Response.self) async throws -> Response {
        let data = try await data(for: endpoint)
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw DomainError.invalidResponse
        }
    }

    func data(for endpoint: Endpoint) async throws -> Data {
        let hosts = [configuration.primaryHost] + configuration.fallbackHosts
        var firstError: (any Error)?

        for host in hosts {
            try Task.checkCancellation()
            guard let url = endpoint.url(host: host, apiKey: configuration.apiKey) else {
                firstError = firstError ?? DomainError.invalidResponse
                continue
            }
            do {
                let (data, response) = try await http.data(from: url)
                guard (200..<300).contains(response.statusCode) else {
                    throw DomainError.server(statusCode: response.statusCode)
                }
                return data
            } catch {
                if Self.isCancellation(error) { throw CancellationError() }
                firstError = firstError ?? error
            }
        }
        // Like the Android app, report why the primary host failed.
        throw Self.domainError(from: firstError)
    }

    private static func isCancellation(_ error: any Error) -> Bool {
        error is CancellationError || (error as? URLError)?.code == .cancelled
    }

    static func domainError(from error: (any Error)?) -> DomainError {
        switch error {
        case let error as DomainError:
            return error
        case let error as URLError:
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
                return .offline
            case .timedOut:
                return .timedOut
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .secureConnectionFailed:
                return .serverUnreachable
            default:
                return .unknown(error.localizedDescription)
            }
        case let error?:
            return .unknown(String(describing: error))
        case nil:
            return .unknown("No hosts configured")
        }
    }
}
