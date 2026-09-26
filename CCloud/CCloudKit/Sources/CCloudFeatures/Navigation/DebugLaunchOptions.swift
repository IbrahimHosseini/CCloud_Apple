#if DEBUG
import Foundation

#if canImport(AppKit) && !canImport(UIKit)
import AppKit
#endif

/// Launch arguments for UI testing and screenshots, applied once per launch. Debug builds only.
///
/// - `-ui-section <movies|series|search|favorites|settings>`: the section to start in.
/// - `-ui-open-first YES`: opens the first title of the first grid that loads.
/// - `-ui-snapshot <path.png>` (Mac): renders the main window to a PNG after
///   `-ui-snapshot-delay` seconds (default 8), for screenshots without screen recording.
@MainActor
enum DebugLaunchOptions {
    static var didApplySection = false
    static var didOpenFirstTitle = false
    private static var didScheduleSnapshot = false

    static func scheduleWindowSnapshotIfRequested() {
        #if canImport(AppKit) && !canImport(UIKit)
        guard !didScheduleSnapshot, let path = UserDefaults.standard.string(forKey: "ui-snapshot") else { return }
        didScheduleSnapshot = true
        let delay = UserDefaults.standard.object(forKey: "ui-snapshot-delay") as? Double ?? 8
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.canBecomeMain }),
                  let view = window.contentView?.superview ?? window.contentView,
                  let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds)
            else { return }
            view.cacheDisplay(in: view.bounds, to: bitmap)
            try? bitmap.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
        }
        #endif
    }
}
#endif
