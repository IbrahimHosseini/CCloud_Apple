@testable import CCloudDomain
import Foundation
import Testing

@Suite("FavoritesBook")
struct FavoritesBookTests {
    let movie = MediaItem.fixture(id: 1)
    let series = MediaItem.fixture(id: 1, kind: .series)
    let date = Date(timeIntervalSince1970: 1_000)

    @Test func addingPutsNewestFirstAndReplacesExisting() {
        var book = FavoritesBook()
        book.add(movie, at: date)
        book.add(series, at: date.addingTimeInterval(1))
        book.add(movie, at: date.addingTimeInterval(2))

        #expect(book.entries.map(\.id) == [movie.id, series.id])
        #expect(book.entries.first?.addedAt == date.addingTimeInterval(2))
    }

    @Test func moviesAndSeriesWithTheSameServerIDAreDifferentFavorites() {
        var book = FavoritesBook()
        book.add(movie, at: date)
        #expect(book.contains(movie.id))
        #expect(!book.contains(series.id))
    }

    @Test func removingAFavoriteTakesItOutOfEveryPlaylist() throws {
        var book = FavoritesBook()
        book.add(movie, at: date)
        let first = try book.createPlaylist(named: "Weekend")
        let second = try book.createPlaylist(named: "Later")
        book.setMembership(of: movie.id, to: [first.id, second.id])

        book.remove(movie.id)

        #expect(book.entries.isEmpty)
        #expect(book.playlists.allSatisfy { $0.itemIDs.isEmpty })
    }

    @Test func removingAllFavoritesKeepsEmptyPlaylists() throws {
        var book = FavoritesBook()
        book.add(movie, at: date)
        let playlist = try book.createPlaylist(named: "Weekend")
        book.setMembership(of: movie.id, to: [playlist.id])

        book.removeAllFavorites()

        #expect(book.entries.isEmpty)
        #expect(book.playlists.count == 1)
        #expect(book.playlist(playlist.id)?.itemIDs.isEmpty == true)
    }

    @Test(arguments: ["", "   ", "\n"])
    func playlistNamesCannotBeBlank(_ name: String) {
        var book = FavoritesBook()
        #expect(throws: PlaylistError.emptyName) {
            try book.createPlaylist(named: name)
        }
    }

    @Test func playlistNamesAreUniqueIgnoringCaseAndSpaces() throws {
        var book = FavoritesBook()
        try book.createPlaylist(named: "Weekend")
        #expect(throws: PlaylistError.duplicateName) {
            try book.createPlaylist(named: "  weekend ")
        }
    }

    @Test func renamingValidatesButAllowsKeepingTheSameName() throws {
        var book = FavoritesBook()
        let weekend = try book.createPlaylist(named: "Weekend")
        try book.createPlaylist(named: "Later")

        try book.renamePlaylist(weekend.id, to: "WEEKEND")
        #expect(book.playlist(weekend.id)?.name == "WEEKEND")

        #expect(throws: PlaylistError.duplicateName) {
            try book.renamePlaylist(weekend.id, to: "later")
        }
        #expect(throws: PlaylistError.notFound) {
            try book.renamePlaylist(PlaylistID(rawValue: "missing"), to: "Name")
        }
    }

    @Test func membershipIsSetExactly() throws {
        var book = FavoritesBook()
        book.add(movie, at: date)
        let first = try book.createPlaylist(named: "A")
        let second = try book.createPlaylist(named: "B")

        book.setMembership(of: movie.id, to: [first.id])
        #expect(book.playlists(containing: movie.id) == [first.id])

        book.setMembership(of: movie.id, to: [second.id])
        #expect(book.playlists(containing: movie.id) == [second.id])

        book.setMembership(of: movie.id, to: [])
        #expect(book.playlists(containing: movie.id).isEmpty)
    }

    @Test func entriesInAPlaylistKeepFavoritesOrder() throws {
        var book = FavoritesBook()
        let items = (1...4).map { MediaItem.fixture(id: $0) }
        for (offset, item) in items.enumerated() {
            book.add(item, at: date.addingTimeInterval(Double(offset)))
        }
        let playlist = try book.createPlaylist(named: "Picks")
        book.setMembership(of: items[0].id, to: [playlist.id])
        book.setMembership(of: items[2].id, to: [playlist.id])

        #expect(book.entries(in: playlist.id).map(\.id) == [items[2].id, items[0].id])
        #expect(book.entries(in: nil).count == 4)
        #expect(book.entries(in: PlaylistID(rawValue: "gone")).isEmpty)
    }
}
