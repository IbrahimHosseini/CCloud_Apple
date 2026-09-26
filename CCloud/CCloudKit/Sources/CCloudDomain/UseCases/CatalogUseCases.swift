import Foundation

/// Loads one page of a feed, applying the content policy.
public struct FetchCatalogPageUseCase: Sendable {
    private let repository: any CatalogRepository
    private let policy: TitleContentPolicy

    public init(repository: any CatalogRepository, policy: TitleContentPolicy) {
        self.repository = repository
        self.policy = policy
    }

    public func execute(_ feed: CatalogFeed, sortedBy order: CatalogSortOrder, page index: Int) async throws -> CatalogPage {
        let items = try await repository.page(feed, sortedBy: order, index: index)
        // The end is decided on the unfiltered page: a page whose titles were all hidden
        // by the policy is not the last one.
        return CatalogPage(index: index, items: items.filter(policy.allows), isLastPage: items.isEmpty)
    }
}

/// Searches movies and series by title.
public struct SearchTitlesUseCase: Sendable {
    private let repository: any SearchRepository
    private let policy: TitleContentPolicy

    public init(repository: any SearchRepository, policy: TitleContentPolicy) {
        self.repository = repository
        self.policy = policy
    }

    /// Results for `query`. An empty or whitespace-only query finds nothing without a request.
    public func execute(_ query: String) async throws -> [MediaItem] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        return try await repository.search(query).filter(policy.allows)
    }
}

public struct FetchSeasonsUseCase: Sendable {
    private let repository: any SeasonRepository

    public init(repository: any SeasonRepository) {
        self.repository = repository
    }

    public func execute(seriesID: Int) async throws -> [Season] {
        try await repository.seasons(ofSeries: seriesID)
    }
}

/// All genres, alphabetically.
public struct FetchGenresUseCase: Sendable {
    private let repository: any GenreRepository

    public init(repository: any GenreRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [Genre] {
        try await repository.genres().sorted {
            $0.title.localizedStandardCompare($1.title) == .orderedAscending
        }
    }
}

public struct FetchCountriesUseCase: Sendable {
    private let repository: any CountryRepository

    public init(repository: any CountryRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [Country] {
        try await repository.countries()
    }
}
