import CCloudDesignSystem
import CCloudDomain
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

enum Clipboard {
    static func copy(_ url: URL) {
        #if os(iOS)
        UIPasteboard.general.url = url
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
        #endif
    }
}

/// Players the user may have installed, which the Android app's "download options" map to.
enum ExternalPlayer: String, CaseIterable, Identifiable {
    case vlc
    case infuse

    var id: Self { self }

    var name: String {
        switch self {
        case .vlc: "VLC"
        case .infuse: "Infuse"
        }
    }

    var actionTitle: String {
        switch self {
        case .vlc: L10n.Actions.openInVLC
        case .infuse: L10n.Actions.openInInfuse
        }
    }

    /// The x-callback URL that hands `media` to the app.
    func callbackURL(for media: URL) -> URL? {
        var components = URLComponents()
        components.host = "x-callback-url"
        switch self {
        case .vlc:
            components.scheme = "vlc-x-callback"
            components.path = "/stream"
        case .infuse:
            components.scheme = "infuse"
            components.path = "/play"
        }
        components.queryItems = [URLQueryItem(name: "url", value: media.absoluteString)]
        // URLComponents leaves "&", "=" and "?" of the media URL unescaped in a query value.
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(of: "&", with: "%26")
            .replacingOccurrences(of: "+", with: "%2B")
        return components.url
    }
}

/// Opens media in another app. Calls `notInstalled` with the app's name when it isn't there.
struct ExternalOpener {
    let openURL: OpenURLAction

    @MainActor
    func open(_ media: URL, in player: ExternalPlayer, notInstalled: @escaping (String) -> Void) {
        #if os(macOS)
        if player == .vlc {
            guard let vlc = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "org.videolan.vlc") else {
                notInstalled(player.name)
                return
            }
            NSWorkspace.shared.open([media], withApplicationAt: vlc, configuration: NSWorkspace.OpenConfiguration())
            return
        }
        #endif
        guard let url = player.callbackURL(for: media) else { return }
        openURL(url) { accepted in
            if !accepted { notInstalled(player.name) }
        }
    }
}
