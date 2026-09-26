import CCloudDesignSystem
import CCloudFeatures
import CCloudPresentation
import SwiftUI

/// The content of the main window, with every dependency injected into the environment.
public struct AppRootView: View {
    private let container: AppContainer
    /// Each window navigates on its own.
    @State private var navigation = AppNavigation()
    @Environment(\.scenePhase) private var scenePhase

    public init(container: AppContainer) {
        self.container = container
    }

    public var body: some View {
        Group {
            // Wait for the saved settings (a few milliseconds) so the theme doesn't flash.
            if container.settings.isLoaded {
                RootView(factory: container, navigation: navigation)
            } else {
                Color.clear
            }
        }
        .injectDependencies(from: container)
        .environment(navigation)
        #if !os(tvOS)
        .focusedSceneValue(\.appNavigation, navigation)
        #endif
        .task { await container.bootstrap() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                Task { await container.settings.flush() }
            }
        }
    }
}

#if os(macOS)
/// The content of the Mac's Settings window.
public struct AppSettingsRootView: View {
    private let container: AppContainer
    @State private var viewModel: SettingsViewModel

    public init(container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: container.makeSettingsViewModel())
    }

    public var body: some View {
        MacSettingsView(viewModel: viewModel)
            .injectDependencies(from: container)
            .task { await container.bootstrap() }
    }
}
#endif

#if !os(tvOS)
/// The app's menu bar commands (Mac, and iPad with a keyboard).
public struct AppMenuCommands: Commands {
    public init() {}

    public var body: some Commands {
        AppCommands()
    }
}
#endif

extension View {
    fileprivate func injectDependencies(from container: AppContainer) -> some View {
        environment(\.viewModelFactory, container)
            .environment(container.favorites)
            .environment(container.watchHistory)
            .environment(container.settings)
            .appTheme(container.settings.settings)
    }
}
