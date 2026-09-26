import CCloudDomain
import SwiftUI

/// A failed load, explained, with a retry button.
public struct ErrorStateView: View {
    private let error: DomainError
    private let retry: () -> Void

    public init(error: DomainError, retry: @escaping () -> Void) {
        self.error = error
        self.retry = retry
    }

    public var body: some View {
        ContentUnavailableView {
            Label(L10n.Errors.title(error), systemImage: error.symbolName)
        } description: {
            Text(L10n.Errors.message(error))
        } actions: {
            Button(L10n.Common.retry, systemImage: "arrow.clockwise", action: retry)
                .adaptiveProminentButtonStyle()
        }
    }
}

public extension DomainError {
    var symbolName: String {
        switch self {
        case .offline: "wifi.slash"
        case .serverUnreachable: "network.slash"
        case .timedOut: "clock.badge.exclamationmark"
        case .server, .invalidResponse: "exclamationmark.icloud"
        case .unknown: "exclamationmark.triangle"
        }
    }
}

/// A centered spinner for the first load of a screen.
public struct LoadingStateView: View {
    public init() {}

    public var body: some View {
        ProgressView()
            #if os(macOS)
            .controlSize(.large)
            #endif
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A grid of redacted poster cards shown while the first page loads.
public struct PosterGridSkeleton: View {
    private let count: Int

    public init(count: Int = 12) {
        self.count = count
    }

    public var body: some View {
        LazyVGrid(columns: Metrics.posterColumns(), spacing: Metrics.rowSpacing) {
            ForEach(0..<count, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: Metrics.posterCornerRadius, style: .continuous)
                        .fill(.quaternary)
                        .aspectRatio(Metrics.posterAspectRatio, contentMode: .fit)
                    Text(verbatim: "Placeholder title")
                        .appFont(.subheadline)
                    Text(verbatim: "2026")
                        .appFont(.caption)
                }
            }
        }
        .redacted(reason: .placeholder)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

/// A slim row at the end of a grid: a spinner while loading more, or a retry button.
public struct LoadMoreFooter: View {
    private let isLoading: Bool
    private let error: DomainError?
    private let retry: () -> Void

    public init(isLoading: Bool, error: DomainError?, retry: @escaping () -> Void) {
        self.isLoading = isLoading
        self.error = error
        self.retry = retry
    }

    public var body: some View {
        Group {
            if error != nil {
                VStack(spacing: 8) {
                    Text(L10n.Catalog.loadMoreFailed)
                        .appFont(.footnote)
                        .foregroundStyle(.secondary)
                    Button(L10n.Common.retry, systemImage: "arrow.clockwise", action: retry)
                        .adaptiveSecondaryButtonStyle()
                }
            } else if isLoading {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
