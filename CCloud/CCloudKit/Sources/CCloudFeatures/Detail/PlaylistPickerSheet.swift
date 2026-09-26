import CCloudDesignSystem
import CCloudDomain
import CCloudPresentation
import SwiftUI

/// Pick which playlists a title belongs to, and create new ones on the way.
struct PlaylistPickerSheet: View {
    let onSave: (Set<PlaylistID>) -> Void

    @State private var selection: Set<PlaylistID>
    @State private var editor = PlaylistEditorState()
    @Environment(FavoritesLibrary.self) private var library
    @Environment(AppSettingsModel.self) private var settings
    @Environment(\.dismiss) private var dismiss

    init(initialSelection: Set<PlaylistID>, onSave: @escaping (Set<PlaylistID>) -> Void) {
        _selection = State(initialValue: initialSelection)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            List {
                if library.book.playlists.isEmpty {
                    Text(L10n.Favorites.noPlaylistsMessage)
                        .foregroundStyle(.secondary)
                }
                ForEach(library.book.playlists) { playlist in
                    Button {
                        toggle(playlist.id)
                    } label: {
                        HStack {
                            Label(playlist.name, systemImage: "music.note.list")
                            Spacer()
                            if selection.contains(playlist.id) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(accentColor)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    // Rows read as list items, not as tinted buttons.
                    .tint(.primary)
                    .accessibilityAddTraits(selection.contains(playlist.id) ? .isSelected : [])
                }
                Button(L10n.Favorites.newPlaylistEllipsis, systemImage: "plus") {
                    editor.startCreating()
                }
            }
            .navigationTitle(L10n.Favorites.choosePlaylists)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Common.save) {
                        onSave(selection)
                        dismiss()
                    }
                }
            }
            .playlistEditor(
                $editor,
                actions: PlaylistActions(
                    create: { name throws(PlaylistError) in try library.createPlaylist(named: name) },
                    rename: { id, name throws(PlaylistError) in try library.renamePlaylist(id, to: name) },
                    delete: { library.deletePlaylist($0) }
                ),
                onCreate: { selection.insert($0.id) }
            )
        }
        #if os(macOS)
        .frame(minWidth: 360, minHeight: 320)
        #endif
    }

    /// The accent chosen in Settings (the rows themselves are tinted with the text color).
    private var accentColor: Color {
        settings.settings.accentColor.color?.swiftUIColor ?? .accentColor
    }

    private func toggle(_ id: PlaylistID) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }
}
