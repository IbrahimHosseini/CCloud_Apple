import CCloudDesignSystem
import CCloudDomain
import CCloudPresentation
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if !os(macOS)
/// The Settings tab on iPhone, iPad and Apple TV.
struct SettingsScreen: View {
    @State private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Form {
            AppearanceSection(viewModel: viewModel)
            PlayerSection(viewModel: viewModel)
            SubtitlesSection(viewModel: viewModel)
            #if os(iOS)
            LanguageSection()
            #endif
            StorageSection(viewModel: viewModel)
            Section {
                NavigationLink {
                    AboutScreen()
                } label: {
                    Label(L10n.About.title, systemImage: "info.circle")
                }
                ResetButton(viewModel: viewModel)
            }
        }
        .navigationTitle(L10n.Tab.settings)
    }
}
#endif

#if os(iOS)
/// iOS picks the app's language in the system Settings (per-app language).
private struct LanguageSection: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        SettingsSection(footer: L10n.Settings.languageFooter) {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                LabeledContent(L10n.Settings.language) {
                    Text(Locale.current.localizedString(forLanguageCode: Locale.current.language.languageCode?.identifier ?? "") ?? "")
                }
            }
            .foregroundStyle(.primary)
        }
    }
}
#endif

#if os(macOS)
/// The Mac's Settings window (⌘,), in the standard tabbed layout.
public struct MacSettingsView: View {
    @State private var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        TabView {
            Tab(L10n.Settings.general, systemImage: "gearshape") {
                Form {
                    AppearanceSection(viewModel: viewModel)
                    Section {
                        ResetButton(viewModel: viewModel)
                    }
                }
                .formStyle(.grouped)
            }
            Tab(L10n.Settings.player, systemImage: "play.rectangle") {
                Form {
                    PlayerSection(viewModel: viewModel)
                    SubtitlesSection(viewModel: viewModel)
                }
                .formStyle(.grouped)
            }
            Tab(L10n.Settings.storage, systemImage: "internaldrive") {
                Form {
                    StorageSection(viewModel: viewModel)
                }
                .formStyle(.grouped)
            }
            Tab(L10n.Settings.about, systemImage: "info.circle") {
                AboutScreen()
            }
        }
        .frame(width: 520)
        .frame(minHeight: 420)
    }
}
#endif
