#if canImport(VLCKitSPM)
import SwiftUI

/// The view VLCKit draws video into.
#if canImport(UIKit)
struct VLCVideoSurface: UIViewRepresentable {
    let engine: VLCPlaybackEngine

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        view.isUserInteractionEnabled = false
        engine.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
#elseif canImport(AppKit)
struct VLCVideoSurface: NSViewRepresentable {
    let engine: VLCPlaybackEngine

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        engine.attach(to: view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif
#endif
