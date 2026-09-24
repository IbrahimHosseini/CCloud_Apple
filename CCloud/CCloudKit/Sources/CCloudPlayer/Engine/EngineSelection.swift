import CCloudDomain
import Foundation

/// The two ways the app can play a file.
enum PlaybackEngineKind: Hashable, Sendable {
    /// AVPlayer with the system player UI: Picture in Picture, AirPlay, native controls.
    case native
    /// VLCKit with the app's own controls, for containers AVPlayer can't open (MKV, AVI…).
    case vlc
}

enum EngineSelection {
    /// Whether VLCKit is linked into this build.
    static var isVLCAvailable: Bool {
        #if canImport(VLCKitSPM)
        true
        #else
        false
        #endif
    }

    /// Containers AVFoundation can't open on its own.
    static let vlcOnlyExtensions: Set<String> = [
        "mkv", "mk3d", "webm", "avi", "divx", "wmv", "asf", "flv", "f4v", "ts", "m2ts", "mts",
        "mpg", "mpeg", "vob", "ogv", "ogg", "rm", "rmvb", "3gp", "3g2",
    ]

    /// The engine to try first. Anything else starts on AVPlayer and moves to VLC only if
    /// AVPlayer fails to open it.
    static func preferredEngine(for source: MediaSource) -> PlaybackEngineKind {
        guard isVLCAvailable else { return .native }
        let format = source.format.lowercased()
        if vlcOnlyExtensions.contains(source.fileExtension) || vlcOnlyExtensions.contains(format) {
            return .vlc
        }
        return .native
    }
}
