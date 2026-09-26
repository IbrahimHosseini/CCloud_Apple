import AVFoundation
import AVKit
import CCloudDesignSystem
import CCloudDomain
import CCloudPresentation
import SwiftUI

/// Plays requests with the right engine and the platform's own player presentation:
/// a full-screen player on iPhone, iPad and Apple TV, a separate window on the Mac.
///
/// Files AVPlayer can't open (MKV and friends) go to VLCKit, either straight away (known
/// extensions) or after AVPlayer reports a failure.
@MainActor
public final class PlaybackCoordinator: PlaybackLauncher {
    private let settings: AppSettingsModel
    private let watchHistory: WatchHistoryLibrary

    #if canImport(UIKit)
    /// The playback on screen (or in Picture in Picture). One at a time.
    private var current: AnyObject?
    #elseif canImport(AppKit)
    /// Open player windows, by request.
    private var windows: [UUID: PlayerWindow] = [:]
    #endif

    public init(settings: AppSettingsModel, watchHistory: WatchHistoryLibrary) {
        self.settings = settings
        self.watchHistory = watchHistory
    }

    public func play(_ request: PlaybackRequest) {
        #if canImport(UIKit)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        switch EngineSelection.preferredEngine(for: request.source) {
        case .native:
            playNatively(request)
        case .vlc:
            playWithVLC(request)
        }
    }

    /// Marks an episode as watched once its video actually starts.
    private func playbackStarted(_ request: PlaybackRequest) {
        if let episode = request.episode {
            watchHistory.markWatched(episode.reference)
        }
    }

    private var subtitleStyle: SubtitleStyle { settings.settings.subtitles }
    private var seekInterval: Int { settings.settings.player.seekInterval }

    #if canImport(VLCKitSPM)
    private func makeVLCScreen(for request: PlaybackRequest, onClose: @escaping () -> Void) -> (VLCPlaybackEngine, some View) {
        let engine = VLCPlaybackEngine(request: request, subtitles: subtitleStyle)
        engine.onStarted = { [weak self] in self?.playbackStarted(request) }
        let screen = VLCPlayerScreen(engine: engine, seekInterval: seekInterval, onClose: onClose)
            .appTheme(settings.settings)
            .environment(\.colorScheme, .dark)
        return (engine, screen)
    }
    #endif
}

// MARK: - iOS, iPadOS, tvOS

#if canImport(UIKit)
extension PlaybackCoordinator {
    private func playNatively(_ request: PlaybackRequest) {
        guard let presenter = UIApplication.topViewController else { return }
        let playback = NativePlayback(request: request, subtitles: subtitleStyle)
        playback.session.onStarted = { [weak self] in self?.playbackStarted(request) }
        playback.session.onFailed = { [weak self, weak playback] _ in
            guard let self, let playback else { return }
            self.fallBackToVLC(from: playback)
        }
        playback.onFinished = { [weak self, weak playback] in
            guard let self, self.current === playback else { return }
            self.current = nil
        }
        current = playback
        presenter.present(playback.controller, animated: true) {
            playback.session.play()
        }
    }

    /// AVPlayer couldn't open the file: close its player and retry with VLC.
    private func fallBackToVLC(from playback: NativePlayback) {
        guard EngineSelection.isVLCAvailable, current === playback else { return }
        let request = playback.session.request
        playback.session.stop()
        playback.controller.dismiss(animated: false) { [weak self] in
            self?.current = nil
            self?.playWithVLC(request)
        }
    }

    private func playWithVLC(_ request: PlaybackRequest) {
        #if canImport(VLCKitSPM)
        guard let presenter = UIApplication.topViewController else { return }
        var host: UIViewController?
        let (engine, screen) = makeVLCScreen(for: request) { [weak self] in
            host?.dismiss(animated: true)
            self?.current = nil
        }
        let controller = PlayerHostingController(rootView: screen, engine: engine)
        controller.modalPresentationStyle = .fullScreen
        controller.overrideUserInterfaceStyle = .dark
        host = controller
        current = controller
        presenter.present(controller, animated: true)
        #else
        playNatively(request)
        #endif
    }
}

/// An AVPlayerViewController playback, kept alive while it's on screen or in Picture in Picture.
@MainActor
private final class NativePlayback: NSObject, @preconcurrency AVPlayerViewControllerDelegate {
    let session: NativePlaybackSession
    let controller = AVPlayerViewController()
    var onFinished: (() -> Void)?
    private var isInPictureInPicture = false

    init(request: PlaybackRequest, subtitles: SubtitleStyle) {
        session = NativePlaybackSession(request: request, subtitles: subtitles)
        super.init()
        controller.player = session.player
        controller.delegate = self
        controller.modalPresentationStyle = .fullScreen
        #if os(iOS)
        controller.allowsPictureInPicturePlayback = true
        controller.canStartPictureInPictureAutomaticallyFromInline = true
        #endif
    }

    private func finish() {
        guard !isInPictureInPicture else { return }
        session.stop()
        onFinished?()
    }

    #if os(iOS)
    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator
    ) {
        coordinator.animate(alongsideTransition: nil) { [weak self] context in
            guard !context.isCancelled else { return }
            MainActor.assumeIsolated { self?.finish() }
        }
    }
    #endif

    #if os(tvOS)
    func playerViewControllerDidEndDismissalTransition(_ playerViewController: AVPlayerViewController) {
        finish()
    }
    #endif

    func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        isInPictureInPicture = true
    }

    func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        isInPictureInPicture = false
        // Closed from the PiP window rather than restored to full screen.
        if controller.presentingViewController == nil {
            finish()
        }
    }

    func playerViewController(
        _ playerViewController: AVPlayerViewController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        guard controller.presentingViewController == nil, let presenter = UIApplication.topViewController else {
            completionHandler(true)
            return
        }
        presenter.present(controller, animated: true) {
            completionHandler(true)
        }
    }
}

#if canImport(VLCKitSPM)
/// Hosts the VLC player full screen and stops it when dismissed.
private final class PlayerHostingController<Content: View>: UIHostingController<Content> {
    private let engine: VLCPlaybackEngine

    init(rootView: Content, engine: VLCPlaybackEngine) {
        self.engine = engine
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || presentingViewController == nil {
            engine.stop()
        }
    }

    #if os(iOS)
    override var prefersHomeIndicatorAutoHidden: Bool { true }
    #endif
}
#endif

extension UIApplication {
    /// The view controller to present the player from: the top of the active window.
    @MainActor
    static var topViewController: UIViewController? {
        let scenes = shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        var top = scene?.keyWindow?.rootViewController ?? scene?.windows.first?.rootViewController
        while let presented = top?.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
    }
}
#endif

// MARK: - macOS

#if canImport(AppKit) && !canImport(UIKit)
extension PlaybackCoordinator {
    private func playNatively(_ request: PlaybackRequest) {
        let session = NativePlaybackSession(request: request, subtitles: subtitleStyle)
        session.onStarted = { [weak self] in self?.playbackStarted(request) }

        let playerView = AVPlayerView()
        playerView.player = session.player
        playerView.controlsStyle = .floating
        playerView.allowsPictureInPicturePlayback = true
        playerView.showsFullScreenToggleButton = true

        let window = PlayerWindow(request: request) { [weak self] in
            session.stop()
            self?.windows[request.id] = nil
        }
        window.show(playerView)
        windows[request.id] = window

        session.onFailed = { [weak self, weak window] _ in
            guard let self, let window, EngineSelection.isVLCAvailable else { return }
            session.stop()
            self.showVLC(request, in: window)
        }
        session.play()
    }

    private func playWithVLC(_ request: PlaybackRequest) {
        let window = PlayerWindow(request: request) { [weak self] in
            self?.windows[request.id] = nil
        }
        windows[request.id] = window
        showVLC(request, in: window)
    }

    private func showVLC(_ request: PlaybackRequest, in window: PlayerWindow) {
        #if canImport(VLCKitSPM)
        let (engine, screen) = makeVLCScreen(for: request) { [weak window] in
            window?.close()
        }
        window.onClose = { [weak self] in
            engine.stop()
            self?.windows[request.id] = nil
        }
        window.show(NSHostingView(rootView: screen))
        #endif
    }
}

/// A resizable, dark window playing one request.
@MainActor
private final class PlayerWindow: NSObject, NSWindowDelegate {
    private let window: NSWindow
    var onClose: () -> Void

    init(request: PlaybackRequest, onClose: @escaping () -> Void) {
        self.onClose = onClose
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1024, height: 576),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        super.init()
        window.title = request.title
        window.subtitle = request.displaySubtitle ?? ""
        window.titlebarAppearsTransparent = true
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = .black
        window.isReleasedWhenClosed = false
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.minSize = NSSize(width: 480, height: 270)
        window.delegate = self
        window.center()
    }

    func show(_ contentView: NSView) {
        window.contentView = contentView
        window.makeKeyAndOrderFront(nil)
    }

    func close() {
        window.close()
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
#endif
