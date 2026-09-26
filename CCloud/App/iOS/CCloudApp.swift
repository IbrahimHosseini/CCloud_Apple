import CCloudComposition
import SwiftUI

/// CCloud for iPhone and iPad.
@main
struct CCloudApp: App {
    @State private var container = AppContainer.makeDefault()

    var body: some Scene {
        WindowGroup {
            AppRootView(container: container)
        }
        .commands {
            AppMenuCommands()
        }
    }
}
