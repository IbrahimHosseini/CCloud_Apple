import CCloudDesignSystem
import CCloudDomain
import CCloudPresentation
import SwiftUI

/// Saved titles, all of them or one playlist, and managing playlists.
struct FavoritesScreen: View {
    @State private var viewModel: FavoritesViewModel
    @State private var editor = PlaylistEditorState()
    @State private var isConfirmingRemoveAll = false
    @State private var editingMemberships: FavoriteEntry?

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    init(viewModel: FavoritesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // The Mac lists playlists in the sidebar instead.
                #if os(tvOS)
                HStack(spacing: 24) {
                    PlaylistChips(viewModel: viewModel)
                    // tvOS has no toolbar: the playlist actions sit at the end of the chips.
                    menu
                }
                .focusSection()
                #elseif os(iOS)
                PlaylistChips(viewModel: viewModel)
                #endif
                content
            }
            .padding(.vertical, Metrics.screenPadding)
        }
        .navigationTitle(viewModel.selectedPlaylist?.name ?? L10n.Tab.favorites)
        #if !os(tvOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                menu
            }
        }
        #endif
        .playlistEditor($editor, viewModel: viewModel)
        .confirmationDialog(L10n.Favorites.removeAllQuestion, isPresented: $isConfirmingRemoveAll, titleVisibility: .visible) {
            Button(L10n.Favorites.removeAllConfirm, role: .destructive) {
                viewModel.removeAllFavorites()
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Favorites.removeAllMessage)
        }
        .sheet(item: $editingMemberships) { entry in
            PlaylistPickerSheet(initialSelection: viewModel.memberships(of: entry)) { selection in
                viewModel.setMemberships(of: entry, to: selection)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        let entries = viewModel.entries
        if entries.isEmpty {
            Group {
                if let playlist = viewModel.selectedPlaylist {
                    ContentUnavailableView(
                        L10n.Favorites.emptyPlaylistTitle,
                        systemImage: "music.note.list",
                        description: Text(L10n.Favorites.emptyPlaylistMessage(playlist.name))
                    )
                } else {
                    ContentUnavailableView(
                        L10n.Favorites.emptyTitle,
                        systemImage: "heart",
                        description: Text(L10n.Favorites.emptyMessage)
                    )
                }
            }
            .padding(.top, 40)
        } else {
            LazyVGrid(columns: Metrics.posterColumns(regularWidth: isRegularWidth), alignment: .leading, spacing: Metrics.rowSpacing) {
                ForEach(entries) { entry in
                    NavigationLink(value: AppRoute.detail(entry.item)) {
                        PosterCard(item: entry.item, showsKind: true)
                    }
                    .posterButtonStyle()
                    .contextMenu { entryMenu(entry) }
                }
            }
            .padding(.horizontal, Metrics.screenPadding)
        }
    }

    @ViewBuilder
    private func entryMenu(_ entry: FavoriteEntry) -> some View {
        Button(L10n.Favorites.editPlaylists, systemImage: "text.badge.plus") {
            editingMemberships = entry
        }
        if viewModel.selectedPlaylist != nil {
            Button(L10n.Favorites.removeFromPlaylist, systemImage: "minus.circle") {
                viewModel.removeFromSelectedPlaylist(entry)
            }
        }
        Button(L10n.Detail.removeFromFavorites, systemImage: "heart.slash", role: .destructive) {
            viewModel.remove(entry)
        }
    }

    /// New playlist, rename or delete the selected one, and remove everything.
    private var menu: some View {
        Menu {
            Button(L10n.Favorites.newPlaylistEllipsis, systemImage: "plus") {
                editor.startCreating()
            }
            if let playlist = viewModel.selectedPlaylist {
                Section(playlist.name) {
                    Button(L10n.Favorites.renameEllipsis, systemImage: "pencil") {
                        editor.startRenaming(playlist)
                    }
                    Button(L10n.Favorites.deletePlaylist, systemImage: "trash", role: .destructive) {
                        editor.confirmDeletion(of: playlist)
                    }
                }
            }
            if viewModel.hasFavorites {
                Section {
                    Button(L10n.Favorites.removeAll, systemImage: "heart.slash", role: .destructive) {
                        isConfirmingRemoveAll = true
                    }
                }
            }
        } label: {
            Label(L10n.Common.more, systemImage: "ellipsis.circle")
        }
        .help(L10n.Common.more)
    }

    private var isRegularWidth: Bool {
        #if os(iOS)
        horizontalSizeClass == .regular
        #else
        false
        #endif
    }
}

#if !os(macOS)
/// "All Favorites" and each playlist as selectable chips.
private struct PlaylistChips: View {
    let viewModel: FavoritesViewModel

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: Metrics.chipSpacing) {
                chip(L10n.Favorites.allFavorites, systemImage: "heart", id: nil)
                ForEach(viewModel.playlists) { playlist in
                    chip(playlist.name, systemImage: "music.note.list", id: playlist.id)
                }
            }
            .padding(.horizontal, Metrics.screenPadding)
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        #if os(tvOS)
        .scrollClipDisabled()
        .focusSection()
        #endif
    }

    private func chip(_ title: String, systemImage: String, id: PlaylistID?) -> some View {
        let isSelected = viewModel.selectedPlaylistID == id
        return Button {
            viewModel.select(id)
        } label: {
            Label {
                Text(title)
                    .centeredLabel(.subheadline)
            } icon: {
                Image(systemName: systemImage)
            }
            .appFont(.subheadline, weight: .semibold)
                #if !os(tvOS)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                .background(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.tertiary), in: Capsule())
                #endif
        }
        #if os(tvOS)
        .buttonStyle(.bordered)
        .tint(isSelected ? .accentColor : nil)
        #else
        .buttonStyle(.plain)
        #endif
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
#endif
