#if canImport(VLCKitSPM)
import CCloudDesignSystem
import CCloudDomain
import SwiftUI

#if canImport(AppKit)
import AppKit
#endif

/// Full-screen playback with VLCKit and the app's own controls.
///
/// iOS: tap to show or hide the controls. tvOS: Play/Pause toggles, left/right skip, up/down
/// show the controls, Menu hides them or closes the player. macOS: space toggles, the arrow
/// keys skip, double-click toggles full screen, moving the mouse shows the controls.
struct VLCPlayerScreen: View {
    let engine: VLCPlaybackEngine
    let seekInterval: Int
    let onClose: () -> Void

    @State fileprivate var controlsVisible = true
    @State private var hideTask: Task<Void, Never>?
    @State private var scrubPosition: Double?
    #if os(tvOS)
    @FocusState private var focusedControl: Control?
    #endif
    #if os(macOS)
    @FocusState private var isFocused: Bool
    #endif

    private enum Control: Hashable {
        case playPause
    }

    #if os(macOS)
    fileprivate var isFocusedBinding: FocusState<Bool>.Binding { $isFocused }

    fileprivate func focusForKeyboard() {
        isFocused = true
    }
    #endif

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VLCVideoSurface(engine: engine)
                .ignoresSafeArea()

            if engine.status == .failed {
                failureView
            } else {
                if engine.status == .opening || engine.status == .buffering {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                        .accessibilityLabel(L10n.Player.buffering)
                }
                if controlsVisible {
                    controls
                        .transition(.opacity)
                }
            }
        }
        .environment(\.colorScheme, .dark)
        .animation(.easeInOut(duration: 0.25), value: controlsVisible)
        .onAppear {
            engine.play()
            scheduleHide()
        }
        .onChange(of: engine.status) { _, status in
            if status == .ended {
                onClose()
            } else if status == .paused {
                showControls(autoHide: false)
            }
        }
        .platformInput(for: self)
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 0) {
            topBar
            Spacer(minLength: 0)
            #if !os(tvOS)
            transportButtons
            Spacer(minLength: 0)
            #endif
            bottomBar
        }
        .padding(outerPadding)
        .background {
            VStack {
                LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 180)
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 220)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .foregroundStyle(.white)
    }

    private var topBar: some View {
        HStack(alignment: .top, spacing: 16) {
            #if !os(tvOS)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .adaptiveGlass(in: Circle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .accessibilityLabel(L10n.Player.close)
            #endif

            VStack(alignment: .leading, spacing: 4) {
                Text(engine.request.title)
                    .appFont(.headline)
                    .lineLimit(1)
                if let subtitle = engine.request.displaySubtitle {
                    Text(subtitle)
                        .appFont(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var transportButtons: some View {
        HStack(spacing: 44) {
            transportButton(Self.skipSymbol(forward: false, seconds: seekInterval), label: L10n.Player.skipBackward(seekInterval), size: .title) {
                engine.skip(by: -seekInterval)
            }
            playPauseButton(size: .largeTitle)
            transportButton(Self.skipSymbol(forward: true, seconds: seekInterval), label: L10n.Player.skipForward(seekInterval), size: .title) {
                engine.skip(by: seekInterval)
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            progress
            HStack(spacing: 20) {
                #if os(tvOS)
                transportButton(Self.skipSymbol(forward: false, seconds: seekInterval), label: L10n.Player.skipBackward(seekInterval), size: .title3) {
                    engine.skip(by: -seekInterval)
                }
                playPauseButton(size: .title3)
                    .focused($focusedControl, equals: .playPause)
                transportButton(Self.skipSymbol(forward: true, seconds: seekInterval), label: L10n.Player.skipForward(seekInterval), size: .title3) {
                    engine.skip(by: seekInterval)
                }
                Spacer()
                #else
                Spacer()
                #endif
                speedMenu
                if engine.audioTracks.filter({ $0.id >= 0 }).count > 1 {
                    audioMenu
                }
                if engine.subtitleTracks.contains(where: { $0.id >= 0 }) {
                    subtitleMenu
                }
                #if os(macOS)
                Button {
                    NSApp.keyWindow?.toggleFullScreen(nil)
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .buttonStyle(.plain)
                .help(L10n.Player.fullScreen)
                .accessibilityLabel(L10n.Player.fullScreen)
                #endif
            }
            .font(controlFont)
        }
    }

    @ViewBuilder
    private var progress: some View {
        let position = scrubPosition ?? engine.position
        let duration = max(engine.duration, 0)
        VStack(spacing: 6) {
            #if os(tvOS)
            ProgressView(value: duration > 0 ? min(position / duration, 1) : 0)
                .tint(.white)
            #else
            Slider(
                value: Binding(get: { min(position, duration) }, set: { scrubPosition = $0 }),
                in: 0...max(duration, 1)
            ) { editing in
                if editing {
                    hideTask?.cancel()
                } else {
                    if let target = scrubPosition { engine.seek(to: target) }
                    scrubPosition = nil
                    scheduleHide()
                }
            }
            .disabled(!engine.isSeekable || duration <= 0)
            .tint(.white)
            .accessibilityLabel(L10n.Player.position)
            #endif
            HStack {
                Text(Formatting.playbackTime(position))
                Spacer()
                if duration > 0 {
                    Text("-" + Formatting.playbackTime(max(duration - position, 0)))
                }
            }
            .appFont(.caption)
            .monospacedDigit()
            .foregroundStyle(.white.opacity(0.85))
            // Times read left to right in every language.
            .environment(\.layoutDirection, .leftToRight)
        }
    }

    private func playPauseButton(size: Font.TextStyle) -> some View {
        let isPlaying = engine.status == .playing || engine.status == .buffering
        return transportButton(isPlaying ? "pause.fill" : "play.fill", label: isPlaying ? L10n.Player.pause : L10n.Player.play, size: size) {
            engine.togglePlayPause()
        }
        #if !os(tvOS)
        .keyboardShortcut(.space, modifiers: [])
        #endif
    }

    private func transportButton(_ symbol: String, label: String, size: Font.TextStyle, action: @escaping () -> Void) -> some View {
        Button {
            action()
            scheduleHide()
        } label: {
            Image(systemName: symbol)
                .font(.system(size, weight: .semibold))
                .contentTransition(.symbolEffect(.replace))
                #if !os(tvOS)
                .frame(width: 64, height: 64)
                .contentShape(Circle())
                #endif
        }
        #if os(tvOS)
        .buttonStyle(.bordered)
        #else
        .buttonStyle(.plain)
        #endif
        .accessibilityLabel(label)
    }

    private var speedMenu: some View {
        Menu {
            Picker(L10n.Player.speed, selection: Binding(get: { engine.rate }, set: { engine.setRate($0) })) {
                ForEach(VLCPlaybackEngine.playbackRates, id: \.self) { rate in
                    Text(Formatting.playbackRate(rate)).tag(rate)
                }
            }
        } label: {
            Label(L10n.Player.speed, systemImage: "gauge.with.dots.needle.67percent")
                .labelStyle(.iconOnly)
        }
        .menuIndicator(.hidden)
        .fixedSize()
        #if !os(tvOS)
        .buttonStyle(.plain)
        #endif
    }

    private var audioMenu: some View {
        trackMenu(L10n.Player.audio, symbol: "speaker.wave.2", tracks: engine.audioTracks, selection: engine.selectedAudioTrack) {
            engine.selectAudioTrack($0)
        }
    }

    private var subtitleMenu: some View {
        trackMenu(L10n.Player.subtitles, symbol: "captions.bubble", tracks: engine.subtitleTracks, selection: engine.selectedSubtitleTrack) {
            engine.selectSubtitleTrack($0)
        }
    }

    private func trackMenu(
        _ title: String,
        symbol: String,
        tracks: [VLCPlaybackEngine.Track],
        selection: Int32,
        select: @escaping @MainActor (Int32) -> Void
    ) -> some View {
        Menu {
            Picker(title, selection: Binding(get: { selection }, set: select)) {
                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                    Text(track.id < 0 ? L10n.Player.off : (track.name.isEmpty ? L10n.Player.track(index) : track.name))
                        .tag(track.id)
                }
            }
        } label: {
            Label(title, systemImage: symbol)
                .labelStyle(.iconOnly)
        }
        .menuIndicator(.hidden)
        .fixedSize()
        #if !os(tvOS)
        .buttonStyle(.plain)
        #endif
    }

    private var failureView: some View {
        ContentUnavailableView {
            Label(L10n.Player.failedTitle, systemImage: "exclamationmark.triangle")
        } description: {
            Text(L10n.Player.failedMessage)
        } actions: {
            Button(L10n.Common.retry) {
                engine.switchSource(to: engine.request.source)
            }
            .adaptiveProminentButtonStyle()
            Button(L10n.Player.close, action: onClose)
                .adaptiveSecondaryButtonStyle()
        }
    }

    // MARK: Visibility

    fileprivate func showControls(autoHide: Bool = true) {
        controlsVisible = true
        if autoHide { scheduleHide() } else { hideTask?.cancel() }
        #if os(tvOS)
        if focusedControl == nil { focusedControl = .playPause }
        #endif
    }

    fileprivate func toggleControls() {
        if controlsVisible {
            hideTask?.cancel()
            controlsVisible = false
        } else {
            showControls()
        }
    }

    fileprivate func hideControls() {
        hideTask?.cancel()
        controlsVisible = false
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled, engine.status == .playing, scrubPosition == nil else { return }
            controlsVisible = false
        }
    }

    // MARK: Platform differences

    #if os(tvOS)
    private let outerPadding: CGFloat = 60
    private let controlFont: Font = .title3
    #elseif os(macOS)
    private let outerPadding: CGFloat = 20
    private let controlFont: Font = .title2
    #else
    private let outerPadding: CGFloat = 16
    private let controlFont: Font = .title2
    #endif

    /// `gobackward.10` exists for common intervals; other values use the plain arrow.
    static func skipSymbol(forward: Bool, seconds: Int) -> String {
        let base = forward ? "goforward" : "gobackward"
        return [5, 10, 15, 30, 45, 60, 75, 90].contains(seconds) ? "\(base).\(seconds)" : base
    }
}

private extension View {
    /// Input handling per platform, kept out of the layout code.
    @ViewBuilder
    func platformInput(for screen: VLCPlayerScreen) -> some View {
        #if os(iOS)
        contentShape(Rectangle())
            .onTapGesture { screen.toggleControls() }
            .statusBarHidden(!screen.controlsVisible)
            .persistentSystemOverlays(screen.controlsVisible ? .automatic : .hidden)
        #elseif os(tvOS)
        focusable(!screen.controlsVisible)
            .onPlayPauseCommand {
                screen.engine.togglePlayPause()
                screen.showControls()
            }
            .onMoveCommand { direction in
                guard !screen.controlsVisible else { return }
                switch direction {
                case .left: screen.engine.skip(by: -screen.seekInterval)
                case .right: screen.engine.skip(by: screen.seekInterval)
                default: screen.showControls()
                }
            }
            .onExitCommand {
                if screen.controlsVisible {
                    screen.hideControls()
                } else {
                    screen.onClose()
                }
            }
        #elseif os(macOS)
        focusable()
            .focusEffectDisabled()
            .focused(screen.isFocusedBinding)
            .onAppear { screen.focusForKeyboard() }
            .onContinuousHover { _ in screen.showControls() }
            .onTapGesture(count: 2) { NSApp.keyWindow?.toggleFullScreen(nil) }
            .onKeyPress(.leftArrow) {
                screen.engine.skip(by: -screen.seekInterval)
                screen.showControls()
                return .handled
            }
            .onKeyPress(.rightArrow) {
                screen.engine.skip(by: screen.seekInterval)
                screen.showControls()
                return .handled
            }
        #else
        self
        #endif
    }
}
#endif
