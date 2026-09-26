import CCloudDesignSystem
import CCloudDomain
import CCloudPresentation
import SwiftUI

/// What the playlist alerts are doing: naming a new playlist, renaming one, confirming a delete.
struct PlaylistEditorState {
    enum Mode: Equatable {
        case create
        case rename(Playlist)
    }

    fileprivate(set) var mode: Mode?
    var name = ""
    fileprivate(set) var pendingDeletion: Playlist?
    fileprivate var error: PlaylistError?

    mutating func startCreating() {
        name = ""
        mode = .create
    }

    mutating func startRenaming(_ playlist: Playlist) {
        name = playlist.name
        mode = .rename(playlist)
    }

    mutating func confirmDeletion(of playlist: Playlist) {
        pendingDeletion = playlist
    }
}

/// The operations the alerts perform, so the same UI works for the Favorites screen and
/// the "Add to Playlist" sheet of a title.
struct PlaylistActions {
    var create: (String) throws(PlaylistError) -> Playlist
    var rename: (PlaylistID, String) throws(PlaylistError) -> Void
    var delete: (PlaylistID) -> Void
}

extension PlaylistActions {
    @MainActor
    init(_ viewModel: FavoritesViewModel) {
        create = { name throws(PlaylistError) in try viewModel.createPlaylist(named: name) }
        rename = { id, name throws(PlaylistError) in try viewModel.renamePlaylist(id, to: name) }
        delete = { id in viewModel.deletePlaylist(id) }
    }
}

extension View {
    func playlistEditor(
        _ state: Binding<PlaylistEditorState>,
        actions: PlaylistActions,
        onCreate: ((Playlist) -> Void)? = nil
    ) -> some View {
        modifier(PlaylistEditorModifier(state: state, actions: actions, onCreate: onCreate))
    }

    func playlistEditor(_ state: Binding<PlaylistEditorState>, viewModel: FavoritesViewModel) -> some View {
        playlistEditor(state, actions: PlaylistActions(viewModel))
    }
}

private struct PlaylistEditorModifier: ViewModifier {
    @Binding var state: PlaylistEditorState
    let actions: PlaylistActions
    let onCreate: ((Playlist) -> Void)?

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: isEditing) {
                TextField(L10n.Favorites.playlistName, text: $state.name)
                    #if os(iOS)
                    .textInputAutocapitalization(.words)
                    #endif
                Button(L10n.Common.cancel, role: .cancel) {}
                Button(confirmTitle, action: commit)
            }
            .alert(
                L10n.Favorites.deletePlaylistQuestion,
                isPresented: isDeleting,
                presenting: state.pendingDeletion
            ) { playlist in
                Button(L10n.Common.delete, role: .destructive) {
                    actions.delete(playlist.id)
                }
                Button(L10n.Common.cancel, role: .cancel) {}
            } message: { playlist in
                Text(L10n.Favorites.deletePlaylistMessage(playlist.name))
            }
            .alert(title, isPresented: hasError, presenting: state.error) { _ in
                Button(L10n.Common.ok) {}
            } message: { error in
                Text(L10n.Favorites.error(error))
            }
    }

    private var title: String {
        if case .rename = state.mode { L10n.Favorites.renamePlaylist } else { L10n.Favorites.newPlaylist }
    }

    private var confirmTitle: String {
        if case .rename = state.mode { L10n.Common.rename } else { L10n.Common.create }
    }

    private var isEditing: Binding<Bool> {
        Binding { state.mode != nil } set: { if !$0 { state.mode = nil } }
    }

    private var isDeleting: Binding<Bool> {
        Binding { state.pendingDeletion != nil } set: { if !$0 { state.pendingDeletion = nil } }
    }

    private var hasError: Binding<Bool> {
        Binding { state.error != nil } set: { if !$0 { state.error = nil } }
    }

    private func commit() {
        guard let mode = state.mode else { return }
        do throws(PlaylistError) {
            switch mode {
            case .create:
                let playlist = try actions.create(state.name)
                onCreate?(playlist)
            case .rename(let playlist):
                try actions.rename(playlist.id, state.name)
            }
            state.mode = nil
        } catch {
            state.mode = nil
            state.error = error
        }
    }
}
