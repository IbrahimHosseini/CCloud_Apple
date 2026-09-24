import CCloudDomain
import Foundation
import Observation

/// The Settings screen (the Settings window on macOS).
@MainActor
@Observable
public final class SettingsViewModel {
    /// Bytes the watched-episode marks take up; `nil` until measured.
    public private(set) var watchHistorySize: Int?

    @ObservationIgnored private let model: AppSettingsModel
    @ObservationIgnored private let watchHistory: WatchHistoryLibrary

    public init(model: AppSettingsModel, watchHistory: WatchHistoryLibrary) {
        self.model = model
        self.watchHistory = watchHistory
    }

    public var settings: AppSettings { model.settings }

    public var watchedEpisodeCount: Int { watchHistory.history.count }

    public func start() async {
        await measureWatchHistory()
    }

    // MARK: Appearance

    public var appearance: Appearance {
        get { model.settings.appearance }
        set { model.update { $0.appearance = newValue } }
    }

    public var accentColor: AccentColorOption {
        get { model.settings.accentColor }
        set { model.update { $0.accentColor = newValue } }
    }

    public var font: FontChoice {
        get { model.settings.font }
        set { model.update { $0.font = newValue } }
    }

    // MARK: Player

    public var seekInterval: Int {
        get { model.settings.player.seekInterval }
        set { model.update { $0.player.seekInterval = newValue.clamped(to: PlayerSettings.seekIntervalRange) } }
    }

    public var subtitleTextColor: SubtitleTextColor {
        get { model.settings.subtitles.textColor }
        set { model.update { $0.subtitles.textColor = newValue } }
    }

    public var subtitleBackground: SubtitleBackground {
        get { model.settings.subtitles.background }
        set { model.update { $0.subtitles.background = newValue } }
    }

    public var subtitleSizePercent: Int {
        get { model.settings.subtitles.sizePercent }
        set { model.update { $0.subtitles.sizePercent = newValue.clamped(to: SubtitleStyle.sizePercentRange) } }
    }

    // MARK: Storage

    public func clearWatchHistory() async {
        watchHistory.removeAll()
        await measureWatchHistory()
    }

    public func resetToDefaults() {
        model.resetToDefaults()
    }

    private func measureWatchHistory() async {
        watchHistorySize = await watchHistory.storageSize()
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
