import CCloudDesignSystem
import CCloudDomain
import CCloudPresentation
import SwiftUI

/// A movie's or series' page: artwork, facts, overview, and what to play.
struct MediaDetailScreen: View {
    @State private var viewModel: MediaDetailViewModel
    @State private var isChoosingPlaylists = false
    @State private var qualityChoice: QualityChoice?
    @State private var missingApp: String?
    /// How far the page is pulled down past its top, and the bars above it. Only iOS sets them.
    @State private var stretch: CGFloat = 0
    @State private var topInset: CGFloat = 0

    @Environment(\.openURL) private var openURL
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isTitleVisible = false
    #endif

    init(viewModel: MediaDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var item: MediaItem { viewModel.item }

    private var displayTitle: String {
        item.title.isEmpty ? L10n.Common.untitled : item.title
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
                DetailHeader(item: item, isWide: isWide, stretch: stretch, topInset: topInset) {
                    actionButtons
                }

                VStack(alignment: .leading, spacing: Metrics.sectionSpacing) {
                    if !item.overview.isEmpty {
                        DetailSection(L10n.Detail.overview) {
                            ExpandableText(item.overview, lineLimit: isWide ? 5 : 4)
                                .appFont(.body)
                                .foregroundStyle(.secondary)
                                #if os(tvOS)
                                .frame(maxWidth: 1100, alignment: .leading)
                                #endif
                        }
                    }
                    facts
                    switch item.kind {
                    case .movie:
                        QualitiesSection(sources: viewModel.sources, play: viewModel.play, open: openExternally)
                    case .series:
                        EpisodesSection(viewModel: viewModel, choose: { qualityChoice = $0 }, open: openExternally)
                    }
                }
                .padding(.horizontal, Metrics.screenPadding)
            }
            .padding(.bottom, Metrics.sectionSpacing)
            // Pin the column to the scroll view's width, so one view that can't shrink doesn't
            // widen the header and every section past the screen.
            .containerRelativeFrame(.horizontal, alignment: .leading)
        }
        #if os(tvOS)
        .background { TVBackdrop(item: item) }
        #endif
        #if os(iOS)
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { topInset = $0 }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top > DetailBackdrop.height(isWide: isWide) - 150
        } action: { _, isPastHeader in
            withAnimation(.easeInOut(duration: 0.2)) { isTitleVisible = isPastHeader }
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            min(max(-(geometry.contentOffset.y + geometry.contentInsets.top), 0), DetailBackdrop.maxStretch)
        } action: { _, pull in
            stretch = pull
        }
        #endif
        #if !os(tvOS)
        // tvOS shows navigation titles over the content; the header already has it there.
        .navigationTitle(displayTitle)
        #endif
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // The header already shows the title; repeat it only once the header is gone.
            ToolbarItem(placement: .principal) {
                Text(displayTitle)
                    .font(.headline)
                    .lineLimit(1)
                    .opacity(isTitleVisible ? 1 : 0)
            }
        }
        #endif
        #if !os(tvOS)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                favoriteButton
                Button(L10n.Detail.addToPlaylist, systemImage: "text.badge.plus") {
                    isChoosingPlaylists = true
                }
                .help(L10n.Detail.addToPlaylist)
            }
        }
        #endif
        .task { viewModel.start() }
        .sheet(isPresented: $isChoosingPlaylists) {
            PlaylistPickerSheet(initialSelection: viewModel.memberships) { selection in
                viewModel.setMemberships(selection)
            }
        }
        .confirmationDialog(L10n.Detail.chooseQuality, isPresented: isChoosingQuality, presenting: qualityChoice) { choice in
            ForEach(choice.episode.sources) { source in
                Button(L10n.Detail.playQuality(source.quality)) {
                    viewModel.play(source, episode: choice.episode, in: choice.season)
                }
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        }
        .alert(missingApp.map(L10n.Actions.appNotInstalledTitle) ?? "", isPresented: isShowingMissingApp) {
            Button(L10n.Common.ok) {}
        } message: {
            Text(missingApp.map(L10n.Actions.appNotInstalledMessage) ?? "")
        }
    }

    // MARK: Actions

    @ViewBuilder
    private var actionButtons: some View {
        switch item.kind {
        case .movie:
            if let preferred = viewModel.preferredSource {
                if viewModel.sources.count > 1 {
                    // Tap plays the best quality; long press (or click-and-hold) picks another.
                    Menu {
                        ForEach(viewModel.sources) { source in
                            Button(L10n.Detail.playQuality(source.quality)) { viewModel.play(source) }
                        }
                    } label: {
                        Label(L10n.Detail.play, systemImage: "play.fill")
                    } primaryAction: {
                        viewModel.play(preferred)
                    }
                    .adaptiveProminentButtonStyle()
                    .fixedSize()
                } else {
                    Button(L10n.Detail.play, systemImage: "play.fill") { viewModel.play(preferred) }
                        .adaptiveProminentButtonStyle()
                }
            }
        case .series:
            if let next = viewModel.nextEpisode {
                Button(L10n.Detail.playEpisode(season: next.season.number, episode: next.episode.number), systemImage: "play.fill") {
                    playOrChoose(next.episode, in: next.season)
                }
                .adaptiveProminentButtonStyle()
            }
        }
        #if os(tvOS)
        favoriteButton
            .buttonStyle(.bordered)
        Button(L10n.Detail.addToPlaylist, systemImage: "text.badge.plus") {
            isChoosingPlaylists = true
        }
        .buttonStyle(.bordered)
        #endif
    }

    private var favoriteButton: some View {
        Button {
            viewModel.toggleFavorite()
        } label: {
            Label(
                viewModel.isFavorite ? L10n.Detail.removeFromFavorites : L10n.Detail.addToFavorites,
                systemImage: viewModel.isFavorite ? "heart.fill" : "heart"
            )
            .contentTransition(.symbolEffect(.replace))
        }
        .help(viewModel.isFavorite ? L10n.Detail.removeFromFavorites : L10n.Detail.addToFavorites)
        .sensoryFeedback(.selection, trigger: viewModel.isFavorite)
    }

    private func playOrChoose(_ episode: Episode, in season: Season) {
        if episode.sources.count == 1, let source = episode.sources.first {
            viewModel.play(source, episode: episode, in: season)
        } else if !episode.sources.isEmpty {
            qualityChoice = QualityChoice(season: season, episode: episode)
        }
    }

    private func openExternally(_ source: MediaSource, _ player: ExternalPlayer) {
        ExternalOpener(openURL: openURL).open(source.url, in: player) { missingApp = $0 }
    }

    // MARK: Facts

    @ViewBuilder
    private var facts: some View {
        if !item.genres.isEmpty {
            DetailSection(L10n.Detail.genres) {
                FlowLayout {
                    ForEach(item.genres) { genre in
                        Chip(genre.title)
                    }
                }
            }
        }
        if !item.countries.isEmpty {
            DetailSection(L10n.Detail.countries) {
                FlowLayout {
                    ForEach(item.countries) { country in
                        NavigationLink(value: AppRoute.country(country)) {
                            Chip(country.title, systemImage: "globe")
                        }
                        #if os(tvOS)
                        .buttonStyle(.bordered)
                        #else
                        .buttonStyle(.plain)
                        #endif
                    }
                }
            }
        }
    }

    // MARK: State helpers

    private var isWide: Bool {
        #if os(iOS)
        horizontalSizeClass == .regular
        #else
        true
        #endif
    }

    private var isChoosingQuality: Binding<Bool> {
        Binding { qualityChoice != nil } set: { if !$0 { qualityChoice = nil } }
    }

    private var isShowingMissingApp: Binding<Bool> {
        Binding { missingApp != nil } set: { if !$0 { missingApp = nil } }
    }
}

struct QualityChoice {
    let season: Season
    let episode: Episode
}

/// A titled block of the detail page.
struct DetailSection<Content: View>: View {
    private let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .appFont(.title3, weight: .bold)
                .accessibilityAddTraits(.isHeader)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
