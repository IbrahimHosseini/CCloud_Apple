import CCloudDomain
@testable import CCloudPresentation
import Foundation
import Testing

@MainActor
@Suite("CatalogViewModel")
struct CatalogViewModelTests {
    private func makeViewModel(_ repository: FakeCatalogRepository, feed: CatalogFeed = .movies(genreID: nil)) -> CatalogViewModel {
        CatalogViewModel(
            feed: feed,
            fetchPage: FetchCatalogPageUseCase(repository: repository, policy: TitleContentPolicy()),
            fetchGenres: FetchGenresUseCase(repository: FakeGenreRepository())
        )
    }

    @Test func loadsTheFirstPageAndSortedGenres() async {
        let repository = FakeCatalogRepository(pages: [0: .success([.fixture(id: 1), .fixture(id: 2)])])
        let viewModel = makeViewModel(repository)

        viewModel.start()
        await waitUntil { viewModel.phase == .loaded && !viewModel.genres.isEmpty }

        #expect(viewModel.items.map(\.serverID) == [1, 2])
        #expect(viewModel.genres.map(\.title) == ["Action", "Drama"])
        #expect(viewModel.hasMorePages)
    }

    @Test func appendsPagesWithoutDuplicatesUntilTheEnd() async {
        let repository = FakeCatalogRepository(pages: [
            0: .success([.fixture(id: 1), .fixture(id: 2)]),
            1: .success([.fixture(id: 2), .fixture(id: 3)]),
        ])
        let viewModel = makeViewModel(repository)
        viewModel.start()
        await waitUntil { viewModel.phase == .loaded }

        viewModel.loadMore()
        await waitUntil { viewModel.items.count == 3 }
        #expect(viewModel.items.map(\.serverID) == [1, 2, 3])

        viewModel.loadMore()
        await waitUntil { !viewModel.hasMorePages }
        viewModel.loadMore()
        try? await Task.sleep(for: .milliseconds(50))
        #expect(repository.requests.map(\.index) == [0, 1, 2])
    }

    @Test func skipsPagesWhoseTitlesAreAllHidden() async {
        let repository = FakeCatalogRepository(pages: [
            0: .success([.fixture(id: 1)]),
            1: .success([.fixture(id: 2, title: "فیلم")]),
            2: .success([.fixture(id: 3)]),
        ])
        let viewModel = makeViewModel(repository)
        viewModel.start()
        await waitUntil { viewModel.phase == .loaded }

        viewModel.loadMore()
        // Page 1 adds nothing visible, so page 2 is fetched without waiting for a scroll.
        await waitUntil { viewModel.items.count == 2 }
        #expect(viewModel.items.map(\.serverID) == [1, 3])
    }

    @Test func aFailingFirstPageCanBeRetried() async {
        let repository = FakeCatalogRepository(pages: [0: .failure(.offline)])
        let viewModel = makeViewModel(repository)
        viewModel.start()
        await waitUntil { viewModel.phase == .failed(.offline) }

        repository.setPage(0, .success([.fixture(id: 7)]))
        viewModel.retry()
        await waitUntil { viewModel.phase == .loaded }
        #expect(viewModel.items.map(\.serverID) == [7])
    }

    @Test func aFailingNextPageKeepsItemsAndOffersRetry() async {
        let repository = FakeCatalogRepository(pages: [0: .success([.fixture(id: 1)]), 1: .failure(.timedOut)])
        let viewModel = makeViewModel(repository)
        viewModel.start()
        await waitUntil { viewModel.phase == .loaded }

        viewModel.loadMore()
        await waitUntil { viewModel.loadMoreError == .timedOut }
        #expect(viewModel.items.count == 1)

        repository.setPage(1, .success([.fixture(id: 2)]))
        viewModel.retry()
        await waitUntil { viewModel.items.count == 2 }
        #expect(viewModel.loadMoreError == nil)
    }

    @Test func changingFiltersStartsOverWithTheNewFeed() async {
        let repository = FakeCatalogRepository(pages: [0: .success([.fixture(id: 1)])])
        let viewModel = makeViewModel(repository)
        viewModel.start()
        await waitUntil { viewModel.phase == .loaded }

        viewModel.selectGenre(5)
        viewModel.selectSortOrder(.imdbRating)
        await waitUntil { repository.requests.count >= 3 && viewModel.phase == .loaded }

        let last = repository.requests.last
        #expect(last?.feed == .movies(genreID: 5))
        #expect(last?.order == .imdbRating)
        #expect(last?.index == 0)
    }

    @Test func countryFeedsHaveNoGenreFilter() {
        let viewModel = makeViewModel(FakeCatalogRepository(pages: [:]), feed: .country(id: 3))
        viewModel.start()
        #expect(viewModel.genres.isEmpty)
        #expect(!viewModel.feed.supportsGenreFilter)
    }
}
