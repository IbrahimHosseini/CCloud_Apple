import Foundation

public struct FavoriteEntry: Identifiable, Hashable, Codable, Sendable {
    public let item: MediaItem
    public let addedAt: Date

    public init(item: MediaItem, addedAt: Date) {
        self.item = item
        self.addedAt = addedAt
    }

    public var id: MediaID { item.id }
}

public struct PlaylistID: Hashable, Codable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static func make() -> PlaylistID {
        PlaylistID(rawValue: UUID().uuidString)
    }
}

/// A user-named subset of the favorites. A title can be in any number of playlists.
public struct Playlist: Identifiable, Hashable, Codable, Sendable {
    public let id: PlaylistID
    public var name: String
    public var itemIDs: [MediaID]

    public init(id: PlaylistID, name: String, itemIDs: [MediaID] = []) {
        self.id = id
        self.name = name
        self.itemIDs = itemIDs
    }
}

/// The favorites and their playlists, with the rules for changing them.
///
/// A value type with no I/O: load it, mutate it, save it.
public struct FavoritesBook: Hashable, Sendable {
    /// Newest first.
    public private(set) var entries: [FavoriteEntry]
    /// In creation order.
    public private(set) var playlists: [Playlist]

    public init(entries: [FavoriteEntry] = [], playlists: [Playlist] = []) {
        self.entries = entries
        self.playlists = playlists
    }

    public static let empty = FavoritesBook()

    // MARK: Favorites

    public func contains(_ id: MediaID) -> Bool {
        entries.contains { $0.id == id }
    }

    /// Adds `item` as the newest favorite. Adding it again moves it to the top and
    /// refreshes the stored copy.
    public mutating func add(_ item: MediaItem, at date: Date) {
        entries.removeAll { $0.id == item.id }
        entries.insert(FavoriteEntry(item: item, addedAt: date), at: 0)
    }

    /// Removes the favorite and takes it out of every playlist.
    public mutating func remove(_ id: MediaID) {
        entries.removeAll { $0.id == id }
        for index in playlists.indices {
            playlists[index].itemIDs.removeAll { $0 == id }
        }
    }

    /// Removes every favorite. Playlists stay, but become empty.
    public mutating func removeAllFavorites() {
        entries.removeAll()
        for index in playlists.indices {
            playlists[index].itemIDs.removeAll()
        }
    }

    /// The favorites in `playlist`, newest first, or all favorites when `playlist` is `nil`.
    public func entries(in playlist: PlaylistID?) -> [FavoriteEntry] {
        guard let playlist else { return entries }
        guard let members = playlists.first(where: { $0.id == playlist }).map({ Set($0.itemIDs) }) else { return [] }
        return entries.filter { members.contains($0.id) }
    }

    // MARK: Playlists

    public func playlist(_ id: PlaylistID) -> Playlist? {
        playlists.first { $0.id == id }
    }

    public func playlists(containing item: MediaID) -> Set<PlaylistID> {
        Set(playlists.filter { $0.itemIDs.contains(item) }.map(\.id))
    }

    @discardableResult
    public mutating func createPlaylist(named rawName: String, id: PlaylistID = .make()) throws(PlaylistError) -> Playlist {
        let name = try validatedName(rawName, excluding: nil)
        let playlist = Playlist(id: id, name: name)
        playlists.append(playlist)
        return playlist
    }

    public mutating func renamePlaylist(_ id: PlaylistID, to rawName: String) throws(PlaylistError) {
        guard let index = playlists.firstIndex(where: { $0.id == id }) else { throw .notFound }
        playlists[index].name = try validatedName(rawName, excluding: id)
    }

    public mutating func deletePlaylist(_ id: PlaylistID) {
        playlists.removeAll { $0.id == id }
    }

    /// Puts a favorite into exactly the given playlists and takes it out of all others.
    /// Unknown playlist ids are ignored.
    public mutating func setMembership(of item: MediaID, to selected: Set<PlaylistID>) {
        for index in playlists.indices {
            let isMember = playlists[index].itemIDs.contains(item)
            let shouldBeMember = selected.contains(playlists[index].id)
            if shouldBeMember && !isMember {
                playlists[index].itemIDs.append(item)
            } else if !shouldBeMember && isMember {
                playlists[index].itemIDs.removeAll { $0 == item }
            }
        }
    }

    private func validatedName(_ rawName: String, excluding id: PlaylistID?) throws(PlaylistError) -> String {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw .emptyName }
        let isTaken = playlists.contains { playlist in
            playlist.id != id && playlist.name.compare(name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }
        guard !isTaken else { throw .duplicateName }
        return name
    }
}
