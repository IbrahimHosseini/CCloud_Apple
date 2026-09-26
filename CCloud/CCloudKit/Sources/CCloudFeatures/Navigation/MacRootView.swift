#if os(macOS)
import CCloudDesignSystem
import CCloudDomain
import CCloudPresentation
import SwiftUI

/// The Mac window: a source-list sidebar (Browse, Library with playlists) and the detail.
struct MacRootView: View {
    @Bindable var navigation: AppNavigation
    let movies: CatalogViewModel
    let series: CatalogViewModel
    let search: SearchViewModel
    let favorites: FavoritesViewModel

    @Environment(FavoritesLibrary.self) private var library
    @State private var playlistEditor = PlaylistEditorState()

    private enum SidebarItem: Hashable {
        case section(AppSection)
        case playlist(PlaylistID)
    }

    private var selection: Binding<SidebarItem?> {
        Binding {
            if navigation.section == .favorites, let playlist = navigation.playlist {
                .playlist(playlist)
            } else {
                .section(navigation.section)
            }
        } set: { item in
            switch item {
            case .section(let section):
                navigation.section = section
                navigation.playlist = nil
            case .playlist(let id):
                navigation.section = .favorites
                navigation.playlist = id
            case nil:
                break
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: selection) {
                Section(L10n.Tab.browse) {
                    sidebarRow(.movies)
                    sidebarRow(.series)
                    sidebarRow(.search)
                }
                Section(L10n.Tab.library) {
                    sidebarRow(.favorites)
                    ForEach(library.book.playlists) { playlist in
                        Label(playlist.name, systemImage: "music.note.list")
                            .tag(SidebarItem.playlist(playlist.id))
                            .contextMenu {
                                Button(L10n.Favorites.renameEllipsis) {
                                    playlistEditor.startRenaming(playlist)
                                }
                                Button(L10n.Favorites.deletePlaylist, role: .destructive) {
                                    playlistEditor.confirmDeletion(of: playlist)
                                }
                            }
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
            .toolbar {
                ToolbarItem {
                    Button(L10n.Favorites.newPlaylist, systemImage: "plus") {
                        playlistEditor.startCreating()
                    }
                    .help(L10n.Favorites.newPlaylist)
                }
            }
        } detail: {
            detail
        }
        .playlistEditor($playlistEditor, viewModel: favorites)
        #if DEBUG
        .onAppear { DebugLaunchOptions.scheduleWindowSnapshotIfRequested() }
        #endif
        .onChange(of: navigation.playlist, initial: true) { _, playlist in
            favorites.select(playlist)
        }
        .onChange(of: favorites.selectedPlaylistID) { _, playlist in
            // A playlist deleted from the Favorites screen falls back to all favorites.
            if navigation.section == .favorites, navigation.playlist != playlist {
                navigation.playlist = playlist
            }
        }
    }

    private func sidebarRow(_ section: AppSection) -> some View {
        Label(section == .favorites ? L10n.Favorites.allFavorites : section.title, systemImage: section.systemImage)
            .tag(SidebarItem.section(section))
    }

    @ViewBuilder
    private var detail: some View {
        switch navigation.section {
        case .movies:
            NavigationStack {
                CatalogScreen(viewModel: movies, title: L10n.Tab.movies)
                    .appRouteDestinations()
            }
            .id(AppSection.movies)
        case .series:
            NavigationStack {
                CatalogScreen(viewModel: series, title: L10n.Tab.series)
                    .appRouteDestinations()
            }
            .id(AppSection.series)
        case .search:
            NavigationStack {
                SearchScreen(viewModel: search, focusRequest: navigation.searchFocusRequest)
                    .appRouteDestinations()
            }
            .id(AppSection.search)
        case .favorites, .settings:
            NavigationStack {
                FavoritesScreen(viewModel: favorites)
                    .appRouteDestinations()
            }
            .id(AppSection.favorites)
        }
    }
}
#endif
