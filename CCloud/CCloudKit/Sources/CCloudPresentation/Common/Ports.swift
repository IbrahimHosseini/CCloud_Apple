import CCloudDomain
import Foundation

/// Starts playback. Implemented by the player module; ViewModels only know this port.
@MainActor
public protocol PlaybackLauncher: AnyObject {
    func play(_ request: PlaybackRequest)
}

/// Creates the ViewModels of screens that are opened while the app runs.
///
/// Implemented by the composition root, which owns every dependency; views get it from
/// the environment, so no view ever builds a ViewModel's dependencies itself.
@MainActor
public protocol ViewModelFactory: AnyObject, Sendable {
    func makeCatalogViewModel(feed: CatalogFeed) -> CatalogViewModel
    func makeSearchViewModel() -> SearchViewModel
    func makeDetailViewModel(item: MediaItem) -> MediaDetailViewModel
    func makeFavoritesViewModel() -> FavoritesViewModel
    func makeSettingsViewModel() -> SettingsViewModel
}
