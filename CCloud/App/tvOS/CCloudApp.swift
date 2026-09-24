import CCloudComposition
import SwiftUI

/// CCloud for Apple TV.
@main
struct CCloudApp: App {
    @State private var container = AppContainer.makeDefault()

    var body: some Scene {
        WindowGroup {
            AppRootView(container: container)
        }
    }
}
