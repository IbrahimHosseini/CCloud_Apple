#if !os(tvOS)
import CCloudDesignSystem
import SwiftUI

public extension FocusedValues {
    /// The navigation of the focused window, for menu commands.
    @Entry var appNavigation: AppNavigation?
}

/// Menu bar items (Mac, and iPad with a keyboard): jump between sections with ⌘1–⌘4 and
/// search with ⌘F. They act on the focused window.
public struct AppCommands: Commands {
    @FocusedValue(\.appNavigation) private var navigation

    public init() {}

    public var body: some Commands {
        CommandGroup(before: .sidebar) {
            ForEach(AppSection.allCases.filter { $0.keyboardShortcut != nil }) { section in
                if let key = section.keyboardShortcut {
                    Button(section.title) {
                        navigation?.show(section)
                    }
                    .keyboardShortcut(key, modifiers: .command)
                    .disabled(navigation == nil)
                }
            }
            Divider()
        }
        CommandGroup(after: .textEditing) {
            Button(L10n.Tab.search) {
                navigation?.focusSearch()
            }
            .keyboardShortcut("f", modifiers: .command)
            .disabled(navigation == nil)
        }
    }
}
#endif
