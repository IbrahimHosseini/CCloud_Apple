import CCloudComposition
import SwiftUI

/// CCloud for Mac: a main window with a sidebar, a Settings window (⌘,), and a window per
/// video being played.
@main
struct CCloudApp: App {
    @State private var container = AppContainer.makeDefault()

    var body: some Scene {
        WindowGroup {
            AppRootView(container: container)
                .frame(minWidth: 820, minHeight: 560)
        }
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
            AppMenuCommands()
        }

        Settings {
            AppSettingsRootView(container: container)
        }
    }
}
