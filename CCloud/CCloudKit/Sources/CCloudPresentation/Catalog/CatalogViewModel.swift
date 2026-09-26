import CCloudDomain
import Foundation
import Observation

/// A paginated, filterable grid of titles: the Movies and Series tabs and a country's page.
@MainActor
@Observable
public final class CatalogViewModel {
    public enum Phase: Equatable {
        /// Nothing requested yet.
        case idle
        /// Loading the first page with nothing to show yet.
        case loading
        case loaded
        /// The first page failed and there's nothing to show.
        case failed(DomainError)
    }

    public let feed: CatalogFeed
    public private(set) var items: [MediaItem] = []
    public private(set) var phase: Phase = .idle
    public private(set) var isLoadingMore = false
    /// Why the last "load more" failed; cleared when retrying.
    public private(set) var loadMoreError: DomainError?
    /// Why the last refresh failed while older items stayed on screen.
    public private(set) var refreshError: DomainError?
    public private(set) var hasMorePages = true

    public private(set) var genres: [Genre] = []
    public private(set) var selectedGenreID: Int?
    public private(set) var sortOrder: CatalogSortOrder = .recentlyAdded

    public var selectedGenre: Genre? {
        selectedGenreID.flatMap { id in genres.first { $0.id == id } }
    }

    @ObservationIgnored private let fetchPage: FetchCatalogPageUseCase
    @ObservationIgnored private let fetchGenres: FetchGenresUseCase?
    @ObservationIgnored private var nextPageIndex = 0
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var loadTask: Task<Void, Never>?
    @ObservationIgnored private var isRefreshing = false
    @ObservationIgnored private var genresRequested = false
    /// Pages in a row that added nothing (all duplicates or hidden by the content policy).
    @ObservationIgnored private var emptyPagesInARow = 0

    /// Start loading the next page when this many items or fewer are left below the one
    /// that just appeared.
    static let prefetchDistance = 8
    /// Stop skipping over empty pages after this many, to avoid hammering the server.
    static let maxEmptyPagesInARow = 5

    public init(feed: CatalogFeed, fetchPage: FetchCatalogPageUseCase, fetchGenres: FetchGenresUseCase?) {
        self.feed = feed
        self.fetchPage = fetchPage
        self.fetchGenres = feed.supportsGenreFilter ? fetchGenres : nil
        selectedGenreID = feed.genreID
    }

    // MARK: Intents

    /// Loads the first page and the genres, once.
    public func start() {
        loadGenresIfNeeded()
        guard phase == .idle else { return }
        reload()
    }

    /// Pull to refresh: reloads from the first page, keeping the current items on screen
    /// until the new ones arrive. Returns when done.
    public func refresh() async {
        loadGenresIfNeeded()
        let generation = beginGeneration()
        isRefreshing = true
        defer { isRefreshing = false }
        await load(pageIndex: 0, generation: generation)
    }

    public func selectGenre(_ genreID: Int?) {
        guard genreID != selectedGenreID else { return }
        selectedGenreID = genreID
        restart()
    }

    public func selectSortOrder(_ order: CatalogSortOrder) {
        guard order != sortOrder else { return }
        sortOrder = order
        restart()
    }

    /// Call when `item` becomes visible; loads the next page near the end of the list.
    public func itemAppeared(_ item: MediaItem) {
        guard let index = items.lastIndex(where: { $0.id == item.id }),
              index >= items.count - Self.prefetchDistance
        else { return }
        loadMore()
    }

    public func loadMore() {
        guard phase == .loaded, hasMorePages, !isLoadingMore, !isRefreshing, loadMoreError == nil, loadTask == nil else { return }
        startLoading(pageIndex: nextPageIndex)
    }

    public func retry() {
        if loadMoreError != nil {
            loadMoreError = nil
            startLoading(pageIndex: nextPageIndex)
        } else {
            reload()
        }
    }

    // MARK: Loading

    private var currentFeed: CatalogFeed {
        feed.filtered(byGenre: selectedGenreID)
    }

    /// Filters changed: drop the current items and start over.
    private func restart() {
        items = []
        phase = .idle
        reload()
    }

    private func reload() {
        startLoading(pageIndex: 0)
    }

    private func startLoading(pageIndex: Int) {
        let generation = beginGeneration()
        loadTask = Task { [weak self] in
            await self?.load(pageIndex: pageIndex, generation: generation)
        }
    }

    /// Invalidates in-flight loads; their results are dropped when they arrive.
    private func beginGeneration() -> Int {
        loadTask?.cancel()
        loadTask = nil
        generation += 1
        isLoadingMore = false
        return generation
    }

    private func load(pageIndex: Int, generation: Int) async {
        let isFirstPage = pageIndex == 0
        if isFirstPage {
            if items.isEmpty { phase = .loading }
            refreshError = nil
            emptyPagesInARow = 0
        } else {
            isLoadingMore = true
            loadMoreError = nil
        }

        do {
            let page = try await fetchPage.execute(currentFeed, sortedBy: sortOrder, page: pageIndex)
            guard generation == self.generation else { return }

            let added: Int
            if isFirstPage {
                items = page.items.uniqued()
                added = items.count
            } else {
                let known = Set(items.map(\.id))
                let fresh = page.items.filter { !known.contains($0.id) }.uniqued()
                items.append(contentsOf: fresh)
                added = fresh.count
            }
            nextPageIndex = pageIndex + 1
            hasMorePages = !page.isLastPage
            phase = .loaded
            isLoadingMore = false
            loadTask = nil

            // A page can add nothing without being the last one. Nothing new would appear
            // to trigger the next page, so fetch it right away.
            emptyPagesInARow = added == 0 ? emptyPagesInARow + 1 : 0
            if added == 0, hasMorePages, emptyPagesInARow < Self.maxEmptyPagesInARow {
                startLoading(pageIndex: nextPageIndex)
            }
        } catch {
            guard generation == self.generation, let error = DomainError(presenting: error) else { return }
            isLoadingMore = false
            loadTask = nil
            if !isFirstPage {
                loadMoreError = error
            } else if items.isEmpty {
                phase = .failed(error)
            } else {
                refreshError = error
            }
        }
    }

    private func loadGenresIfNeeded() {
        guard let fetchGenres, !genresRequested else { return }
        genresRequested = true
        Task { [weak self] in
            do {
                let genres = try await fetchGenres.execute()
                self?.genres = genres
            } catch {
                // The filter just offers "All genres"; try again on the next refresh.
                self?.genresRequested = false
            }
        }
    }
}

extension Array where Element == MediaItem {
    /// Drops later duplicates, keeping order.
    func uniqued() -> [MediaItem] {
        var seen = Set<MediaID>()
        return filter { seen.insert($0.id).inserted }
    }
}
