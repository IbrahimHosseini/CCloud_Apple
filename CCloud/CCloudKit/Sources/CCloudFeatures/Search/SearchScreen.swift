import CCloudDesignSystem
import CCloudDomain
import CCloudPresentation
import SwiftUI

/// Search by title; before searching, browse titles by country.
struct SearchScreen: View {
    @State private var viewModel: SearchViewModel
    /// Changes when the Mac's "Find" command asks for the search field.
    private let focusRequest: Int

    @State private var isSearchFieldFocused = false
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    init(viewModel: SearchViewModel, focusRequest: Int = 0) {
        _viewModel = State(initialValue: viewModel)
        self.focusRequest = focusRequest
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        content
            .navigationTitle(L10n.Tab.search)
            #if os(tvOS)
            .searchable(text: $viewModel.query, prompt: L10n.Search.prompt)
            #else
            .searchable(text: $viewModel.query, isPresented: $isSearchFieldFocused, prompt: L10n.Search.prompt)
            #endif
            .onSubmit(of: .search) { viewModel.submit() }
            .task { viewModel.start() }
            .onChange(of: focusRequest) { isSearchFieldFocused = true }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isBrowsing {
            countries
        } else {
            switch viewModel.results {
            case .idle, .loading:
                LoadingStateView()
            case .failed(let error):
                ErrorStateView(error: error, retry: viewModel.retry)
            case .loaded(let items) where items.isEmpty:
                ContentUnavailableView.search(text: viewModel.searchedQuery ?? viewModel.query)
            case .loaded(let items):
                results(items)
            }
        }
    }

    private func results(_ items: [MediaItem]) -> some View {
        ScrollView {
            LazyVGrid(columns: Metrics.posterColumns(regularWidth: isRegularWidth), alignment: .leading, spacing: Metrics.rowSpacing) {
                ForEach(items) { item in
                    NavigationLink(value: AppRoute.detail(item)) {
                        PosterCard(item: item, showsKind: true)
                    }
                    .posterButtonStyle()
                    .titleContextMenu(item)
                }
            }
            .padding(Metrics.screenPadding)
        }
    }

    @ViewBuilder
    private var countries: some View {
        switch viewModel.countries {
        case .idle, .loading:
            LoadingStateView()
        case .failed:
            ContentUnavailableView {
                Label(L10n.Search.startTitle, systemImage: "magnifyingglass")
            } description: {
                Text(L10n.Search.startMessage)
            } actions: {
                Button(L10n.Common.retry, systemImage: "arrow.clockwise", action: viewModel.retryCountries)
                    .adaptiveSecondaryButtonStyle()
            }
        case .loaded(let countries) where countries.isEmpty:
            ContentUnavailableView(L10n.Search.startTitle, systemImage: "magnifyingglass", description: Text(L10n.Search.startMessage))
        case .loaded(let countries):
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.Search.browseByCountry)
                        .appFont(.title3, weight: .bold)
                        .accessibilityAddTraits(.isHeader)
                    LazyVGrid(columns: countryColumns, spacing: Metrics.rowSpacing) {
                        ForEach(countries) { country in
                            NavigationLink(value: AppRoute.country(country)) {
                                CountryBadge(country: country)
                            }
                            .posterButtonStyle()
                        }
                    }
                }
                .padding(Metrics.screenPadding)
            }
        }
    }

    private var countryColumns: [GridItem] {
        #if os(tvOS)
        [GridItem(.adaptive(minimum: 200, maximum: 240), spacing: 48)]
        #elseif os(macOS)
        [GridItem(.adaptive(minimum: 110, maximum: 140), spacing: 20)]
        #else
        [GridItem(.adaptive(minimum: 76, maximum: 100), spacing: 14)]
        #endif
    }

    private var isRegularWidth: Bool {
        #if os(iOS)
        horizontalSizeClass == .regular
        #else
        false
        #endif
    }
}

/// A country's flag in a circle with its name.
private struct CountryBadge: View {
    let country: Country

    var body: some View {
        VStack(spacing: 10) {
            RemoteImage(url: country.imageURL) {
                ZStack {
                    LinearGradient(colors: Palette.placeholderGradient(seed: country.title), startPoint: .top, endPoint: .bottom)
                    Text(String(country.title.prefix(1)))
                        .appFont(.title2, weight: .bold)
                        .foregroundStyle(.white)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(.primary.opacity(0.1), lineWidth: 1))
            #if os(tvOS)
            .hoverEffect(.highlight)
            #endif
            Text(country.title)
                .appFont(.footnote, weight: .medium)
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .combine)
    }
}
