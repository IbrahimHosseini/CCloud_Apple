import CCloudDomain
import Foundation
import Observation

/// Search by title, plus the list of countries to browse before searching.
@MainActor
@Observable
public final class SearchViewModel {
    /// The text in the search field.
    public var query = "" {
        didSet { queryDidChange(from: oldValue) }
    }
    /// The query the current results are for.
    public private(set) var searchedQuery: String?
    public private(set) var results: LoadState<[MediaItem]> = .idle
    public private(set) var countries: LoadState<[Country]> = .idle

    /// `true` before the first search and after clearing: show the countries.
    public var isBrowsing: Bool { searchedQuery == nil && !results.isLoading }

    @ObservationIgnored private let search: SearchTitlesUseCase
    @ObservationIgnored private let fetchCountries: FetchCountriesUseCase
    @ObservationIgnored private let liveSearchDelay: Duration?
    @ObservationIgnored private var searchTask: Task<Void, Never>?

    /// With a `liveSearchDelay`, results update while typing, after that pause (for tvOS,
    /// whose keyboard has no search key). Otherwise searching waits for `submit()`, like
    /// the Android app, to keep requests down.
    public init(search: SearchTitlesUseCase, fetchCountries: FetchCountriesUseCase, liveSearchDelay: Duration? = nil) {
        self.search = search
        self.fetchCountries = fetchCountries
        self.liveSearchDelay = liveSearchDelay
    }

    public func start() {
        guard countries.isIdle else { return }
        loadCountries()
    }

    public func submit() {
        runSearch(query, after: nil)
    }

    public func retry() {
        if countries.error != nil { loadCountries() }
        if results.error != nil { runSearch(searchedQuery ?? query, after: nil) }
    }

    public func clear() {
        query = ""
    }

    public func retryCountries() {
        loadCountries()
    }

    // MARK: Private

    private func queryDidChange(from oldValue: String) {
        guard query != oldValue else { return }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            searchTask?.cancel()
            searchTask = nil
            searchedQuery = nil
            results = .idle
        } else if let liveSearchDelay, trimmed.count >= 2 {
            runSearch(trimmed, after: liveSearchDelay)
        }
    }

    private func runSearch(_ rawQuery: String, after delay: Duration?) {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        guard query != searchedQuery || results.error != nil || delay == nil else { return }

        searchTask?.cancel()
        searchTask = Task { [weak self, search] in
            if let delay {
                try? await Task.sleep(for: delay)
                guard !Task.isCancelled else { return }
            }
            self?.results = .loading
            do {
                let items = try await search.execute(query)
                guard !Task.isCancelled else { return }
                self?.searchedQuery = query
                self?.results = .loaded(items)
            } catch {
                guard !Task.isCancelled, let error = DomainError(presenting: error) else { return }
                self?.searchedQuery = query
                self?.results = .failed(error)
            }
        }
    }

    private func loadCountries() {
        countries = .loading
        Task { [weak self, fetchCountries] in
            do {
                let countries = try await fetchCountries.execute()
                self?.countries = .loaded(countries)
            } catch {
                guard let error = DomainError(presenting: error) else { return }
                self?.countries = .failed(error)
            }
        }
    }
}
