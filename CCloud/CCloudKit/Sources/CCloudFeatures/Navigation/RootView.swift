import CCloudDesignSystem
import CCloudDomain
import CCloudPresentation
import SwiftUI

/// The app's main window content. Each platform gets its own navigation:
///
/// - iPhone: a tab bar.
/// - iPad: a tab bar that turns into a sidebar.
/// - Apple TV: the tvOS sidebar/tab bar driven by focus.
/// - Mac: a sidebar with sections and playlists; Settings lives in its own window (⌘,).
public struct RootView: View {
    @Bindable private var navigation: AppNavigation
    @State private var movies: CatalogViewModel
    @State private var series: CatalogViewModel
    @State private var search: SearchViewModel
    @State private var favorites: FavoritesViewModel
    #if !os(macOS)
    @State private var settings: SettingsViewModel
    #endif

    public init(factory: any ViewModelFactory, navigation: AppNavigation) {
        self.navigation = navigation
        #if DEBUG
        // UI testing and screenshots: `-ui-section settings` starts in that section.
        if !DebugLaunchOptions.didApplySection,
           let name = UserDefaults.standard.string(forKey: "ui-section"),
           let section = AppSection.allCases.first(where: { "\($0)" == name }) {
            DebugLaunchOptions.didApplySection = true
            navigation.section = section
        }
        #endif
        // The tab screens live as long as the window, so switching tabs keeps their state.
        _movies = State(initialValue: factory.makeCatalogViewModel(feed: .movies(genreID: nil)))
        _series = State(initialValue: factory.makeCatalogViewModel(feed: .series(genreID: nil)))
        _search = State(initialValue: factory.makeSearchViewModel())
        _favorites = State(initialValue: factory.makeFavoritesViewModel())
        #if !os(macOS)
        _settings = State(initialValue: factory.makeSettingsViewModel())
        #endif
    }

    public var body: some View {
        #if os(macOS)
        MacRootView(navigation: navigation, movies: movies, series: series, search: search, favorites: favorites)
        #else
        TabView(selection: $navigation.section) {
            Tab(AppSection.movies.title, systemImage: AppSection.movies.systemImage, value: AppSection.movies) {
                NavigationStack {
                    CatalogScreen(viewModel: movies, title: L10n.Tab.movies)
                        .appRouteDestinations()
                }
            }
            Tab(AppSection.series.title, systemImage: AppSection.series.systemImage, value: AppSection.series) {
                NavigationStack {
                    CatalogScreen(viewModel: series, title: L10n.Tab.series)
                        .appRouteDestinations()
                }
            }
            Tab(AppSection.favorites.title, systemImage: AppSection.favorites.systemImage, value: AppSection.favorites) {
                NavigationStack {
                    FavoritesScreen(viewModel: favorites)
                        .appRouteDestinations()
                }
            }
            Tab(AppSection.settings.title, systemImage: AppSection.settings.systemImage, value: AppSection.settings) {
                NavigationStack {
                    SettingsScreen(viewModel: settings)
                }
            }
            Tab(AppSection.search.title, systemImage: AppSection.search.systemImage, value: AppSection.search, role: .search) {
                NavigationStack {
                    SearchScreen(viewModel: search)
                        .appRouteDestinations()
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .modifier(MinimizingTabBar())
        #endif
    }
}

#if !os(macOS)
/// On iPhone with OS 26, the tab bar shrinks while scrolling down, like the system apps.
private struct MinimizingTabBar: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
        #else
        content
        #endif
    }
}
#endif
