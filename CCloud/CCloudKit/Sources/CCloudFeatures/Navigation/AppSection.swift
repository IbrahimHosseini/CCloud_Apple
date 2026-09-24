import CCloudDesignSystem
import CCloudDomain
import SwiftUI

/// The app's top-level sections: tabs on iPhone, iPad and Apple TV, sidebar rows on the Mac.
public enum AppSection: Hashable, CaseIterable, Identifiable, Codable {
    case movies
    case series
    case search
    case favorites
    case settings

    public var id: Self { self }

    var title: String {
        switch self {
        case .movies: L10n.Tab.movies
        case .series: L10n.Tab.series
        case .search: L10n.Tab.search
        case .favorites: L10n.Tab.favorites
        case .settings: L10n.Tab.settings
        }
    }

    var systemImage: String {
        switch self {
        case .movies: "film"
        case .series: "tv"
        case .search: "magnifyingglass"
        case .favorites: "heart"
        case .settings: "gearshape"
        }
    }

    /// ⌘1, ⌘2… on the Mac and iPad with a keyboard.
    var keyboardShortcut: KeyEquivalent? {
        switch self {
        case .movies: "1"
        case .series: "2"
        case .search: "3"
        case .favorites: "4"
        case .settings: nil
        }
    }
}

/// The app-wide navigation state, so menu commands can switch sections.
@MainActor
@Observable
public final class AppNavigation {
    public var section: AppSection = .movies
    /// The playlist selected in the Mac sidebar; `nil` is "All Favorites".
    public var playlist: PlaylistID?
    var searchFocusRequest = 0

    public init() {}

    public func show(_ section: AppSection) {
        self.section = section
        if section != .favorites {
            playlist = nil
        }
    }

    /// Opens Search and puts the cursor in the search field.
    public func focusSearch() {
        section = .search
        searchFocusRequest += 1
    }
}
