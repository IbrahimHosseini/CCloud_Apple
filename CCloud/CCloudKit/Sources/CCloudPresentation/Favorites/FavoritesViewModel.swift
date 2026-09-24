import CCloudDomain
import Foundation
import Observation

/// The Favorites screen: all favorites or one playlist, and managing playlists.
@MainActor
@Observable
public final class FavoritesViewModel {
    /// `nil` shows all favorites.
    public var selectedPlaylistID: PlaylistID?

    @ObservationIgnored private let library: FavoritesLibrary

    public init(library: FavoritesLibrary) {
        self.library = library
    }

    public var isLoaded: Bool { library.isLoaded }

    public var playlists: [Playlist] { library.book.playlists }

    public var selectedPlaylist: Playlist? {
        selectedPlaylistID.flatMap(library.book.playlist)
    }

    /// The favorites shown: the selected playlist's, or all of them.
    public var entries: [FavoriteEntry] {
        // A deleted playlist falls back to all favorites.
        library.book.entries(in: selectedPlaylist?.id)
    }

    public var hasFavorites: Bool { !library.book.entries.isEmpty }

    public func select(_ playlistID: PlaylistID?) {
        selectedPlaylistID = playlistID
    }

    // MARK: Favorites

    public func remove(_ entry: FavoriteEntry) {
        library.remove(entry.id)
    }

    /// Removes the entry from the selected playlist only; the favorite stays.
    public func removeFromSelectedPlaylist(_ entry: FavoriteEntry) {
        guard let playlist = selectedPlaylist else { return }
        var memberships = library.playlists(containing: entry.id)
        memberships.remove(playlist.id)
        library.setMembership(of: entry.id, to: memberships)
    }

    public func removeAllFavorites() {
        library.removeAllFavorites()
    }

    public func memberships(of entry: FavoriteEntry) -> Set<PlaylistID> {
        library.playlists(containing: entry.id)
    }

    public func setMemberships(of entry: FavoriteEntry, to playlists: Set<PlaylistID>) {
        library.setMembership(of: entry.id, to: playlists)
    }

    // MARK: Playlists

    @discardableResult
    public func createPlaylist(named name: String) throws(PlaylistError) -> Playlist {
        try library.createPlaylist(named: name)
    }

    public func renamePlaylist(_ id: PlaylistID, to name: String) throws(PlaylistError) {
        try library.renamePlaylist(id, to: name)
    }

    public func deletePlaylist(_ id: PlaylistID) {
        if selectedPlaylistID == id {
            selectedPlaylistID = nil
        }
        library.deletePlaylist(id)
    }
}
