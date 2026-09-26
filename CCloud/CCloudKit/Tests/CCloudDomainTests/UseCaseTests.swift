@testable import CCloudDomain
import Foundation
import Testing

@Suite("Use cases and policies")
struct UseCaseTests {
    @Test(arguments: [
        ("The Matrix", false),
        ("ماتریکس", true),
        ("Matrix دوبله", true),
        ("1917", false),
        ("Amélie", false),
    ])
    func persianScriptDetection(title: String, isPersian: Bool) {
        #expect(TitleContentPolicy.containsPersianScript(title) == isPersian)
    }

    @Test func policyCanBeTurnedOff() {
        let item = MediaItem.fixture(id: 1, title: "ماتریکس")
        #expect(!TitleContentPolicy().allows(item))
        #expect(TitleContentPolicy(hidesPersianTitles: false).allows(item))
    }

    @Test func pagesHideFilteredTitlesButOnlyEndWhenTheServerRunsOut() async throws {
        let repository = StubCatalogRepository(pages: [
            0: [.fixture(id: 1), .fixture(id: 2, title: "فیلم")],
            1: [.fixture(id: 3, title: "سریال")],
        ])
        let useCase = FetchCatalogPageUseCase(repository: repository, policy: TitleContentPolicy())

        let first = try await useCase.execute(.movies(genreID: nil), sortedBy: .recentlyAdded, page: 0)
        #expect(first.items.map(\.serverID) == [1])
        #expect(!first.isLastPage)

        // Everything on this page is hidden, yet more pages may follow.
        let second = try await useCase.execute(.movies(genreID: nil), sortedBy: .recentlyAdded, page: 1)
        #expect(second.items.isEmpty)
        #expect(!second.isLastPage)

        let third = try await useCase.execute(.movies(genreID: nil), sortedBy: .recentlyAdded, page: 2)
        #expect(third.isLastPage)
    }

    @Test func blankSearchesDontReachTheServer() async throws {
        let repository = CountingSearchRepository(results: [.fixture(id: 1)])
        let useCase = SearchTitlesUseCase(repository: repository, policy: TitleContentPolicy())

        #expect(try await useCase.execute("   ").isEmpty)
        #expect(repository.queries.isEmpty)

        #expect(try await useCase.execute("  matrix ").count == 1)
        #expect(repository.queries == ["matrix"])
    }

    @Test func feedsNarrowAndWidenByGenre() {
        #expect(CatalogFeed.movies(genreID: nil).filtered(byGenre: 4) == .movies(genreID: 4))
        #expect(CatalogFeed.series(genreID: 4).filtered(byGenre: nil) == .series(genreID: nil))
        #expect(CatalogFeed.country(id: 9).filtered(byGenre: 4) == .country(id: 9))
        #expect(!CatalogFeed.country(id: 9).supportsGenreFilter)
    }

    @Test func watchHistoryTracksEpisodes() {
        let episode = EpisodeReference(seriesID: 1, seasonID: 2, episodeID: 3)
        var history = WatchHistory()
        history.markWatched(episode, at: Date(timeIntervalSince1970: 10))
        #expect(history.isWatched(episode))
        #expect(!history.isWatched(EpisodeReference(seriesID: 1, seasonID: 2, episodeID: 4)))

        history.markUnwatched(episode)
        #expect(history.count == 0)
    }

    @Test func settingsSavedBeforeAFieldExistedStillDecode() throws {
        let json = #"{"appearance":"dark","accentColor":"teal"}"#
        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))
        #expect(settings.appearance == .dark)
        #expect(settings.accentColor == .teal)
        #expect(settings.font == .system)
        #expect(settings.player.seekInterval == 10)
        #expect(settings.subtitles == SubtitleStyle())
    }

    @Test func settingsClampOutOfRangeValues() {
        #expect(PlayerSettings(seekInterval: 100).seekInterval == 30)
        #expect(SubtitleStyle(sizePercent: 10).sizePercent == 50)
    }

    @Test func colorsRoundTripThroughHex() {
        #expect(RGBAColor(hex: 0x6650A4).rgbHex == 0x6650A4)
        #expect(SubtitleTextColor.yellow.color.rgbHex == 0xFFFF00)
    }
}
