#if canImport(VLCKitSPM)
import CCloudDomain
import Foundation
import Observation
import VLCKitSPM

#if canImport(UIKit)
import UIKit
typealias PlatformView = UIView
#elseif canImport(AppKit)
import AppKit
typealias PlatformView = NSView
#endif

/// A VLCKit player exposed as observable state for the SwiftUI controls.
///
/// VLCKit reports through notifications on arbitrary threads; polling its properties from
/// the main actor a few times a second is simpler and plenty for a progress bar.
@MainActor
@Observable
final class VLCPlaybackEngine {
    enum Status: Equatable {
        case opening
        case buffering
        case playing
        case paused
        case ended
        case failed
    }

    struct Track: Identifiable, Hashable {
        let id: Int32
        let name: String
    }

    private(set) var status: Status = .opening
    /// Seconds.
    private(set) var position: Double = 0
    /// Seconds; 0 until known.
    private(set) var duration: Double = 0
    private(set) var isSeekable = false
    private(set) var rate: Float = 1
    private(set) var audioTracks: [Track] = []
    private(set) var subtitleTracks: [Track] = []
    private(set) var selectedAudioTrack: Int32 = -1
    private(set) var selectedSubtitleTrack: Int32 = -1
    private(set) var request: PlaybackRequest

    /// Called once, when the video first starts playing.
    @ObservationIgnored var onStarted: (() -> Void)?

    @ObservationIgnored private let player: VLCMediaPlayer
    @ObservationIgnored private var pollTask: Task<Void, Never>?
    @ObservationIgnored private var hasStarted = false
    /// A seek target shown until VLC catches up, so the bar doesn't jump back.
    @ObservationIgnored private var pendingSeek: (target: Double, until: Date)?

    static let playbackRates: [Float] = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]

    init(request: PlaybackRequest, subtitles: SubtitleStyle) {
        self.request = request
        player = VLCMediaPlayer(options: Self.libraryOptions(for: subtitles))
        load(request.source)
    }

    // MARK: Control

    func attach(to view: PlatformView) {
        player.drawable = view
    }

    func play() {
        player.play()
        startPolling()
    }

    func pause() {
        player.pause()
    }

    func togglePlayPause() {
        if player.isPlaying { pause() } else { play() }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
        player.stop()
        player.drawable = nil
    }

    func seek(to seconds: Double) {
        guard isSeekable, duration > 0 else { return }
        let target = min(max(seconds, 0), duration)
        player.time = VLCTime(int: Int32(target * 1000))
        position = target
        pendingSeek = (target, Date().addingTimeInterval(1.5))
    }

    func skip(by seconds: Int) {
        seek(to: position + Double(seconds))
    }

    func setRate(_ rate: Float) {
        player.rate = rate
        self.rate = rate
    }

    func selectAudioTrack(_ id: Int32) {
        player.currentAudioTrackIndex = id
        selectedAudioTrack = id
    }

    func selectSubtitleTrack(_ id: Int32) {
        player.currentVideoSubTitleIndex = id
        selectedSubtitleTrack = id
    }

    /// Starts over with another source of the same title (e.g. a different quality).
    func switchSource(to source: MediaSource) {
        let resumeAt = position
        request = request.with(source: source)
        player.stop()
        load(source)
        status = .opening
        play()
        if resumeAt > 5 {
            Task { [weak self] in
                // VLC ignores seeks until the new media is open.
                for _ in 0..<40 where self?.isSeekable == false {
                    try? await Task.sleep(for: .milliseconds(250))
                }
                self?.seek(to: resumeAt)
            }
        }
    }

    // MARK: State

    private func load(_ source: MediaSource) {
        let media = VLCMedia(url: source.url)
        // Remote files are often served slowly; a bigger buffer avoids stalls.
        media.addOption(":network-caching=3000")
        player.media = media
    }

    private func startPolling() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.refresh()
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }

    private func refresh() {
        let lengthMilliseconds = player.media?.length.intValue ?? 0
        duration = max(Double(lengthMilliseconds) / 1000, 0)
        isSeekable = player.isSeekable

        let reported = Double(player.time.intValue) / 1000
        if let pending = pendingSeek, Date() < pending.until, abs(reported - pending.target) > 2 {
            position = pending.target
        } else {
            pendingSeek = nil
            position = max(reported, 0)
        }

        status = switch player.state {
        case .opening: .opening
        case .buffering: player.isPlaying ? .playing : .buffering
        case .playing: .playing
        case .paused: .paused
        case .ended, .stopped: status == .opening ? .opening : .ended
        case .error: .failed
        default: status
        }

        if status == .playing, !hasStarted {
            hasStarted = true
            onStarted?()
        }
        refreshTracks()
    }

    private func refreshTracks() {
        let audio = Self.tracks(names: player.audioTrackNames, ids: player.audioTrackIndexes)
        if audio != audioTracks { audioTracks = audio }
        let subtitles = Self.tracks(names: player.videoSubTitlesNames, ids: player.videoSubTitlesIndexes)
        if subtitles != subtitleTracks { subtitleTracks = subtitles }
        selectedAudioTrack = player.currentAudioTrackIndex
        selectedSubtitleTrack = player.currentVideoSubTitleIndex
    }

    private static func tracks(names: [Any], ids: [Any]) -> [Track] {
        zip(names, ids).compactMap { name, id in
            guard let id = (id as? NSNumber)?.int32Value else { return nil }
            return Track(id: id, name: (name as? String) ?? "\(id)")
        }
    }

    /// libVLC options styling subtitles the way the user chose in Settings.
    static func libraryOptions(for style: SubtitleStyle) -> [String] {
        let background = style.background.color
        return [
            "--freetype-color=\(style.textColor.color.rgbHex)",
            "--freetype-background-color=\(background.rgbHex)",
            "--freetype-background-opacity=\(Int((background.alpha * 255).rounded()))",
            // An outline keeps text readable when there's no background box.
            "--freetype-outline-thickness=\(style.background == .none ? 4 : 0)",
            "--sub-text-scale=\(style.sizePercent)",
        ]
    }
}
#endif
