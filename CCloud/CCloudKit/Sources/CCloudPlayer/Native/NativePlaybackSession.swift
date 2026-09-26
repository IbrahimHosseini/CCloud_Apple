import AVFoundation
import CCloudDesignSystem
import CCloudDomain
import CoreMedia
import Foundation

extension PlaybackRequest {
    /// "S1 · E3 · Episode title" for episodes, `nil` for movies.
    var displaySubtitle: String? {
        guard let episode else { return nil }
        let code = L10n.Detail.episodeCode(season: episode.seasonNumber, episode: episode.episodeNumber)
        return episode.episodeTitle.isEmpty ? code : "\(code) · \(episode.episodeTitle)"
    }
}

/// One AVPlayer playback: builds the item (subtitle style, title metadata) and reports when
/// playback really starts or the file can't be opened.
@MainActor
final class NativePlaybackSession {
    let request: PlaybackRequest
    let player: AVPlayer

    /// Called once, when the video first starts playing.
    var onStarted: (() -> Void)?
    /// Called once, when the item fails (e.g. an unsupported container).
    var onFailed: ((any Error) -> Void)?

    private var observations: [NSKeyValueObservation] = []
    private var hasStarted = false
    private var hasFailed = false

    init(request: PlaybackRequest, subtitles: SubtitleStyle) {
        self.request = request
        let item = AVPlayerItem(url: request.source.url)
        item.textStyleRules = Self.textStyleRules(for: subtitles)
        #if os(tvOS) || os(iOS)
        item.externalMetadata = Self.metadata(for: request)
        #endif
        player = AVPlayer(playerItem: item)
        player.appliesMediaSelectionCriteriaAutomatically = true
        observe(item)
    }

    func play() {
        player.play()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        observations.removeAll()
    }

    private func observe(_ item: AVPlayerItem) {
        // KVO can call back on any thread: the handlers are @Sendable and hop to the main actor.
        observations.append(item.observe(\.status, options: [.new]) { @Sendable [weak self] item, _ in
            guard item.status == .failed else { return }
            let error = item.error ?? AVError(.unknown)
            Task { @MainActor in self?.fail(error) }
        })
        observations.append(player.observe(\.timeControlStatus, options: [.new]) { @Sendable [weak self] player, _ in
            guard player.timeControlStatus == .playing else { return }
            Task { @MainActor in self?.start() }
        })
    }

    private func start() {
        guard !hasStarted else { return }
        hasStarted = true
        onStarted?()
    }

    private func fail(_ error: any Error) {
        guard !hasFailed else { return }
        hasFailed = true
        onFailed?(error)
    }

    /// The user's subtitle style for text tracks AVPlayer renders (WebVTT, CEA-608…).
    static func textStyleRules(for style: SubtitleStyle) -> [AVTextStyleRule] {
        func argb(_ color: RGBAColor) -> [NSNumber] {
            [color.alpha, color.red, color.green, color.blue].map { NSNumber(value: $0) }
        }
        let attributes: [String: Any] = [
            kCMTextMarkupAttribute_ForegroundColorARGB as String: argb(style.textColor.color),
            kCMTextMarkupAttribute_CharacterBackgroundColorARGB as String: argb(style.background.color),
            kCMTextMarkupAttribute_RelativeFontSize as String: NSNumber(value: style.sizePercent),
        ]
        return AVTextStyleRule(textMarkupAttributes: attributes).map { [$0] } ?? []
    }

    #if os(tvOS) || os(iOS)
    /// Title shown by the system player's info panel and Now Playing.
    private static func metadata(for request: PlaybackRequest) -> [AVMetadataItem] {
        func item(_ identifier: AVMetadataIdentifier, _ value: String) -> AVMetadataItem {
            let item = AVMutableMetadataItem()
            item.identifier = identifier
            item.value = value as NSString
            item.extendedLanguageTag = "und"
            return item.copy() as! AVMetadataItem
        }
        var items = [item(.commonIdentifierTitle, request.title)]
        if let subtitle = request.displaySubtitle {
            items.append(item(.iTunesMetadataTrackSubTitle, subtitle))
        }
        return items
    }
    #endif
}
