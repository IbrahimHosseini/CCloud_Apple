import CCloudDomain
import Foundation

/// The lifecycle of something loaded asynchronously.
public enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(DomainError)

    public var value: Value? {
        if case .loaded(let value) = self { value } else { nil }
    }

    public var error: DomainError? {
        if case .failed(let error) = self { error } else { nil }
    }

    public var isLoading: Bool {
        if case .loading = self { true } else { false }
    }

    public var isIdle: Bool {
        if case .idle = self { true } else { false }
    }
}

extension LoadState: Equatable where Value: Equatable {}
extension LoadState: Sendable where Value: Sendable {}

extension DomainError {
    /// Any error as a `DomainError`, or `nil` for cancellation, which isn't a failure.
    public init?(presenting error: any Error) {
        switch error {
        case is CancellationError:
            return nil
        case let error as DomainError:
            self = error
        case let error as URLError where error.code == .cancelled:
            return nil
        default:
            self = .unknown(String(describing: error))
        }
    }
}
