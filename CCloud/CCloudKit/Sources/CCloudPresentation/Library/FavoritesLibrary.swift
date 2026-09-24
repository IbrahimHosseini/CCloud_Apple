import CCloudDomain
import Foundation
import Observation

/// The user's favorites and playlists, shared by every screen so a change made in one
/// (e.g. the heart on a detail page) shows up everywhere immediately.
@MainActor
@Observable
public final class FavoritesLibrary {
    public private(set) var book: FavoritesBook = .empty
    public private(set) var isLoaded = false

    @ObservationIgnored private let useCase: FavoritesUseCase
    @ObservationIgnored private let now: @Sendable () -> Date
    @ObservationIgnored private var pendingSave: Task<Void, Never>?

    public init(useCase: FavoritesUseCase, now: @escaping @Sendable () -> Date = Date.init) {
        self.useCase = useCase
        self.now = now
    }

    public func load() async {
        guard !isLoaded else { return }
        book = await useCase.load()
        isLoaded = true
    }

    // MARK: Favorites

    public func contains(_ id: MediaID) -> Bool {
        book.contains(id)
    }

    public func add(_ item: MediaItem) {
        mutate { $0.add(item, at: now()) }
    }

    public func remove(_ id: MediaID) {
        mutate { $0.remove(id) }
    }

    /// Adds `item`, or removes it if it's already a favorite. Returns whether it is one now.
    @discardableResult
    public func toggle(_ item: MediaItem) -> Bool {
        if contains(item.id) {
            remove(item.id)
            return false
        }
        add(item)
        return true
    }

    public func removeAllFavorites() {
        mutate { $0.removeAllFavorites() }
    }

    // MARK: Playlists

    @discardableResult
    public func createPlaylist(named name: String) throws(PlaylistError) -> Playlist {
        var updated = book
        let playlist = try updated.createPlaylist(named: name)
        commit(updated)
        return playlist
    }

    public func renamePlaylist(_ id: PlaylistID, to name: String) throws(PlaylistError) {
        var updated = book
        try updated.renamePlaylist(id, to: name)
        commit(updated)
    }

    public func deletePlaylist(_ id: PlaylistID) {
        mutate { $0.deletePlaylist(id) }
    }

    public func playlists(containing item: MediaID) -> Set<PlaylistID> {
        book.playlists(containing: item)
    }

    public func setMembership(of item: MediaID, to playlists: Set<PlaylistID>) {
        mutate { $0.setMembership(of: item, to: playlists) }
    }

    // MARK: Saving

    private func mutate(_ change: (inout FavoritesBook) -> Void) {
        var updated = book
        change(&updated)
        commit(updated)
    }

    private func commit(_ updated: FavoritesBook) {
        guard updated != book else { return }
        book = updated
        // Saves run one after another, each writing the latest state.
        let previous = pendingSave
        pendingSave = Task { [useCase] in
            await previous?.value
            try? await useCase.save(self.book)
        }
    }
}
