import CCloudDesignSystem
import CCloudDomain
import CCloudPresentation
import SwiftUI

// Settings sections shared by the iPhone/iPad/Apple TV Settings tab and the Mac Settings window.

/// A `Section` whose title and footer are styled explicitly. The app sets one font on the whole
/// window, which would otherwise make a section's title and its footer the same size and color.
struct SettingsSection<Content: View>: View {
    private let title: String?
    private let footer: String?
    private let content: Content

    init(_ title: String? = nil, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        Section {
            content
        } header: {
            if let title {
                Text(title)
                    .appFont(.subheadline, weight: .semibold)
                    .foregroundStyle(.primary)
                    .textCase(nil)
            }
        } footer: {
            if let footer {
                Text(footer)
                    .appFont(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct AppearanceSection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        SettingsSection(L10n.Settings.appearance) {
            Picker(L10n.Settings.theme, selection: $viewModel.appearance) {
                ForEach(Appearance.allCases, id: \.self) { appearance in
                    Text(L10n.Settings.appearance(appearance)).tag(appearance)
                }
            }
            #if os(iOS)
            .pickerStyle(.segmented)
            #endif

            #if os(tvOS)
            Picker(L10n.Settings.accentColor, selection: $viewModel.accentColor) {
                ForEach(AccentColorOption.allCases, id: \.self) { option in
                    Label {
                        Text(L10n.Settings.accentColor(option))
                    } icon: {
                        ColorSwatch(color: option.swatchColor, size: 32)
                    }
                    .tag(option)
                }
            }
            #else
            SwatchSetting(L10n.Settings.accentColor) {
                SwatchRow(options: AccentColorOption.allCases, selection: $viewModel.accentColor) { option in
                    (option.swatchColor, L10n.Settings.accentColor(option))
                }
            }
            #endif

            Picker(L10n.Settings.font, selection: $viewModel.font) {
                ForEach(FontChoice.allCases, id: \.self) { font in
                    Text(L10n.Settings.font(font))
                        .font(.app(.body, choice: font))
                        .tag(font)
                }
            }
        }
    }
}

struct PlayerSection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        SettingsSection(L10n.Settings.player, footer: L10n.Settings.seekIntervalFooter) {
            #if os(tvOS)
            Picker(L10n.Settings.seekInterval, selection: $viewModel.seekInterval) {
                ForEach([5, 10, 15, 20, 25, 30], id: \.self) { seconds in
                    Text(L10n.Settings.seconds(seconds)).tag(seconds)
                }
            }
            #else
            Stepper(value: $viewModel.seekInterval, in: PlayerSettings.seekIntervalRange) {
                LabeledContent(L10n.Settings.seekInterval, value: L10n.Settings.seconds(viewModel.seekInterval))
            }
            #endif
        }
    }
}

struct SubtitlesSection: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        SettingsSection(L10n.Settings.subtitles) {
            SubtitlePreview(style: viewModel.settings.subtitles)
                #if os(tvOS)
                .frame(maxWidth: 640)
                #else
                .frame(maxWidth: 420)
                #endif
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .padding(.vertical, 4)

            #if os(tvOS)
            Picker(L10n.Settings.textColor, selection: $viewModel.subtitleTextColor) {
                ForEach(SubtitleTextColor.allCases, id: \.self) { color in
                    Label {
                        Text(L10n.Settings.subtitleColor(color))
                    } icon: {
                        ColorSwatch(color: color.color.swiftUIColor, size: 32)
                    }
                    .tag(color)
                }
            }
            Picker(L10n.Settings.background, selection: $viewModel.subtitleBackground) {
                ForEach(SubtitleBackground.allCases, id: \.self) { background in
                    Label {
                        Text(L10n.Settings.subtitleBackground(background))
                    } icon: {
                        ColorSwatch(color: background.swatchColor, size: 32)
                    }
                    .tag(background)
                }
            }
            Picker(L10n.Settings.textSize, selection: $viewModel.subtitleSizePercent) {
                ForEach(Array(stride(from: 50, through: 250, by: 25)), id: \.self) { percent in
                    Text(Formatting.percent(percent)).tag(percent)
                }
            }
            #else
            SwatchSetting(L10n.Settings.textColor) {
                SwatchRow(options: SubtitleTextColor.allCases, selection: $viewModel.subtitleTextColor) { color in
                    (color.color.swiftUIColor, L10n.Settings.subtitleColor(color))
                }
            }
            SwatchSetting(L10n.Settings.background) {
                SwatchRow(options: SubtitleBackground.allCases, selection: $viewModel.subtitleBackground) { background in
                    (background.swatchColor, L10n.Settings.subtitleBackground(background))
                }
            }
            LabeledContent(L10n.Settings.textSize) {
                HStack {
                    Slider(
                        value: Binding(
                            get: { Double(viewModel.subtitleSizePercent) },
                            set: { viewModel.subtitleSizePercent = Int($0.rounded()) }
                        ),
                        in: Double(SubtitleStyle.sizePercentRange.lowerBound)...Double(SubtitleStyle.sizePercentRange.upperBound),
                        step: 10
                    )
                    .frame(minWidth: 120, maxWidth: 220)
                    Text(Formatting.percent(viewModel.subtitleSizePercent))
                        .monospacedDigit()
                        .frame(minWidth: 48, alignment: .trailing)
                }
            }
            #endif
        }
    }
}

struct StorageSection: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var isConfirmingClear = false

    var body: some View {
        SettingsSection(L10n.Settings.storage) {
            LabeledContent(L10n.Settings.watchedEpisodes) {
                Text(summary)
                    .monospacedDigit()
            }
            Button(L10n.Settings.clearWatched, role: .destructive) {
                isConfirmingClear = true
            }
            .disabled(viewModel.watchedEpisodeCount == 0)
            .confirmationDialog(L10n.Settings.clearWatchedQuestion, isPresented: $isConfirmingClear, titleVisibility: .visible) {
                Button(L10n.Settings.clear, role: .destructive) {
                    Task { await viewModel.clearWatchHistory() }
                }
                Button(L10n.Common.cancel, role: .cancel) {}
            } message: {
                Text(L10n.Settings.clearWatchedMessage)
            }
        }
        .task { await viewModel.start() }
    }

    private var summary: String {
        let count = L10n.Settings.watchedEpisodeCount(viewModel.watchedEpisodeCount)
        guard let size = viewModel.watchHistorySize, size > 0 else { return count }
        return "\(count) · \(Formatting.bytes(size))"
    }
}

struct ResetButton: View {
    let viewModel: SettingsViewModel
    @State private var isConfirming = false

    var body: some View {
        Button(L10n.Settings.reset, role: .destructive) {
            isConfirming = true
        }
        .confirmationDialog(L10n.Settings.resetQuestion, isPresented: $isConfirming, titleVisibility: .visible) {
            Button(L10n.Settings.resetConfirm, role: .destructive) {
                viewModel.resetToDefaults()
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Settings.resetMessage)
        }
    }
}

extension AccentColorOption {
    /// `nil` for the system accent, drawn as the "automatic" swatch.
    var swatchColor: Color? {
        color?.swiftUIColor ?? .accentColor
    }
}

#if !os(tvOS)
/// A labeled row of swatches. On iPhone the row sits under its label and scrolls, so nine
/// swatches fit any screen width.
private struct SwatchSetting<Row: View>: View {
    private let title: String
    private let row: Row

    init(_ title: String, @ViewBuilder row: () -> Row) {
        self.title = title
        self.row = row()
    }

    var body: some View {
        #if os(iOS)
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
            ScrollView(.horizontal) {
                row
                    .padding(.vertical, 4)
                    .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)
        }
        #else
        LabeledContent(title) {
            row
        }
        #endif
    }
}

/// A row of tappable color swatches.
struct SwatchRow<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let appearance: (Option) -> (color: Color?, name: String)

    var body: some View {
        HStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                let (color, name) = appearance(option)
                Button {
                    selection = option
                } label: {
                    ColorSwatch(color: color, isSelected: option == selection, size: 24)
                        .padding(3)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help(name)
                .accessibilityLabel(name)
                .accessibilityAddTraits(option == selection ? .isSelected : [])
            }
        }
    }
}
#endif
