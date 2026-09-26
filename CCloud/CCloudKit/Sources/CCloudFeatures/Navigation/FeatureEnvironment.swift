import CCloudDomain
import CCloudPresentation
import SwiftUI

public extension EnvironmentValues {
    /// Creates ViewModels for screens pushed while navigating. Injected by the composition root.
    @Entry var viewModelFactory: (any ViewModelFactory)? = nil
}

extension EnvironmentValues {
    /// The injected factory. Screens are only ever shown under the app's root view, which
    /// always injects one, so a missing factory is a programming error.
    var factory: any ViewModelFactory {
        guard let viewModelFactory else {
            preconditionFailure("No ViewModelFactory in the environment. Show screens inside CCloud's root view.")
        }
        return viewModelFactory
    }
}

/// Places a screen can navigate to.
public enum AppRoute: Hashable {
    case detail(MediaItem)
    case country(Country)
}

/// The screen for a route, with its ViewModel made by the injected factory.
struct RouteDestination: View {
    let route: AppRoute
    @Environment(\.factory) private var factory

    var body: some View {
        switch route {
        case .detail(let item):
            MediaDetailScreen(viewModel: factory.makeDetailViewModel(item: item))
        case .country(let country):
            CatalogScreen(
                viewModel: factory.makeCatalogViewModel(feed: .country(id: country.id)),
                title: country.title
            )
        }
    }
}

extension View {
    /// Registers the app's routes on a navigation stack.
    func appRouteDestinations() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            RouteDestination(route: route)
        }
    }
}
