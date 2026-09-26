import CCloudDesignSystem
import CCloudDomain
import CCloudPresentation
import SwiftUI

/// A grid of titles with genre and sort filters: the Movies and Series tabs and country pages.
struct CatalogScreen: View {
    @State private var viewModel: CatalogViewModel
    private let title: String

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    #if DEBUG
    @State private var debugOpenedItem: MediaItem?
    #endif

    init(viewModel: CatalogViewModel, title: String) {
        _viewModel = State(initialValue: viewModel)
        self.title = title
    }

    var body: some View {
        content
            .navigationTitle(title)
            #if !os(tvOS)
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    CatalogFilterMenu(viewModel: viewModel)
                    #if os(macOS)
                    Button(L10n.Common.refresh, systemImage: "arrow.clockwise") {
                        Task { await viewModel.refresh() }
                    }
                    .keyboardShortcut("r", modifiers: .command)
                    .help(L10n.Common.refresh)
                    #endif
                }
            }
            #endif
            .task { viewModel.start() }
            #if DEBUG
            // UI testing and screenshots: `-ui-open-first YES` opens the first title.
            .navigationDestination(item: $debugOpenedItem) { item in
                RouteDestination(route: .detail(item))
            }
            .onChange(of: viewModel.items.first) { _, first in
                guard !DebugLaunchOptions.didOpenFirstTitle, let first,
                      UserDefaults.standard.bool(forKey: "ui-open-first") else { return }
                DebugLaunchOptions.didOpenFirstTitle = true
                debugOpenedItem = first
            }
            #endif
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .idle, .loading:
            ScrollView {
                #if os(tvOS)
                CatalogFilterBar(viewModel: viewModel)
                #endif
                PosterGridSkeleton()
                    .padding(Metrics.screenPadding)
            }
            .scrollDisabled(true)
        case .failed(let error):
            ErrorStateView(error: error, retry: viewModel.retry)
        case .loaded:
            grid
        }
    }

    private var grid: some View {
        ScrollView {
            #if os(tvOS)
            CatalogFilterBar(viewModel: viewModel)
            #endif
            if let refreshError = viewModel.refreshError {
                Label(L10n.Catalog.refreshFailed, systemImage: refreshError.symbolName)
                    .appFont(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            if viewModel.items.isEmpty {
                ContentUnavailableView(
                    L10n.Catalog.emptyTitle,
                    systemImage: "film.stack",
                    description: Text(isCountry ? L10n.Catalog.countryEmptyMessage : L10n.Catalog.emptyMessage)
                )
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: Metrics.posterColumns(regularWidth: isRegularWidth), alignment: .leading, spacing: Metrics.rowSpacing) {
                    ForEach(viewModel.items) { item in
                        NavigationLink(value: AppRoute.detail(item)) {
                            PosterCard(item: item, showsKind: isCountry)
                        }
                        .posterButtonStyle()
                        .titleContextMenu(item)
                        .onAppear { viewModel.itemAppeared(item) }
                    }
                }
                .padding(Metrics.screenPadding)

                if viewModel.hasMorePages || viewModel.loadMoreError != nil {
                    LoadMoreFooter(isLoading: viewModel.isLoadingMore, error: viewModel.loadMoreError, retry: viewModel.retry)
                        .onAppear { viewModel.loadMore() }
                }
            }
        }
        #if !os(tvOS)
        .refreshable { await viewModel.refresh() }
        #endif
    }

    private var isCountry: Bool {
        if case .country = viewModel.feed { true } else { false }
    }

    private var isRegularWidth: Bool {
        #if os(iOS)
        horizontalSizeClass == .regular
        #else
        false
        #endif
    }
}

/// Genre and sort pickers in one toolbar menu. The icon fills when a filter is active.
private struct CatalogFilterMenu: View {
    let viewModel: CatalogViewModel

    var body: some View {
        Menu {
            if viewModel.feed.supportsGenreFilter {
                Picker(L10n.Catalog.genre, selection: genreSelection) {
                    Text(L10n.Catalog.allGenres).tag(Int?.none)
                    ForEach(viewModel.genres) { genre in
                        Text(genre.title).tag(Int?.some(genre.id))
                    }
                }
                .pickerStyle(.menu)
            }
            Picker(L10n.Catalog.sortBy, selection: sortSelection) {
                ForEach(CatalogSortOrder.allCases, id: \.self) { order in
                    Text(L10n.Catalog.sortOrder(order)).tag(order)
                }
            }
            .pickerStyle(.inline)
        } label: {
            Label(L10n.Catalog.filter, systemImage: isFiltered
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease")
        }
        .help(L10n.Catalog.filter)
    }

    private var isFiltered: Bool {
        viewModel.selectedGenreID != nil || viewModel.sortOrder != .recentlyAdded
    }

    private var genreSelection: Binding<Int?> {
        Binding(get: { viewModel.selectedGenreID }, set: { viewModel.selectGenre($0) })
    }

    private var sortSelection: Binding<CatalogSortOrder> {
        Binding(get: { viewModel.sortOrder }, set: { viewModel.selectSortOrder($0) })
    }
}

#if os(tvOS)
/// The filters as a row of focusable menus above the grid (tvOS has no toolbar).
private struct CatalogFilterBar: View {
    let viewModel: CatalogViewModel

    var body: some View {
        HStack(spacing: 24) {
            if viewModel.feed.supportsGenreFilter {
                Menu {
                    Picker(L10n.Catalog.genre, selection: Binding(get: { viewModel.selectedGenreID }, set: { viewModel.selectGenre($0) })) {
                        Text(L10n.Catalog.allGenres).tag(Int?.none)
                        ForEach(viewModel.genres) { genre in
                            Text(genre.title).tag(Int?.some(genre.id))
                        }
                    }
                } label: {
                    Label(viewModel.selectedGenre?.title ?? L10n.Catalog.allGenres, systemImage: "theatermasks")
                }
            }
            Menu {
                Picker(L10n.Catalog.sortBy, selection: Binding(get: { viewModel.sortOrder }, set: { viewModel.selectSortOrder($0) })) {
                    ForEach(CatalogSortOrder.allCases, id: \.self) { order in
                        Text(L10n.Catalog.sortOrder(order)).tag(order)
                    }
                }
            } label: {
                Label(L10n.Catalog.sortOrder(viewModel.sortOrder), systemImage: "arrow.up.arrow.down")
            }
            Spacer()
        }
        .focusSection()
    }
}
#endif
