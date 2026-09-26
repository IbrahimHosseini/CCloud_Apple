import CCloudDesignSystem
import CCloudDomain
import CCloudPresentation
import SwiftUI

extension View {
    /// Long press (iPhone, iPad, Apple TV) or right-click (Mac) on a poster.
    func titleContextMenu(_ item: MediaItem) -> some View {
        modifier(TitleContextMenu(item: item))
    }
}

private struct TitleContextMenu: ViewModifier {
    let item: MediaItem
    @Environment(FavoritesLibrary.self) private var favorites

    func body(content: Content) -> some View {
        content.contextMenu {
            let isFavorite = favorites.contains(item.id)
            Button {
                favorites.toggle(item)
            } label: {
                Label(
                    isFavorite ? L10n.Detail.removeFromFavorites : L10n.Detail.addToFavorites,
                    systemImage: isFavorite ? "heart.slash" : "heart"
                )
            }
            #if !os(tvOS)
            if let artwork = item.posterURL {
                Button {
                    Clipboard.copy(artwork)
                } label: {
                    Label(L10n.Actions.copyImageLink, systemImage: "link")
                }
            }
            #endif
        }
    }
}
