import CCloudDomain
import Foundation
import Observation

/// The app's settings, shared by every screen and the player. Changes apply at once and
/// are saved shortly after (so dragging a slider doesn't write on every step).
@MainActor
@Observable
public final class AppSettingsModel {
    public private(set) var settings: AppSettings = .default
    public private(set) var isLoaded = false

    @ObservationIgnored private let useCase: SettingsUseCase
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private let saveDelay: Duration

    public init(useCase: SettingsUseCase, saveDelay: Duration = .milliseconds(300)) {
        self.useCase = useCase
        self.saveDelay = saveDelay
    }

    public func load() async {
        guard !isLoaded else { return }
        settings = await useCase.load()
        isLoaded = true
    }

    public func update(_ change: (inout AppSettings) -> Void) {
        var updated = settings
        change(&updated)
        guard updated != settings else { return }
        settings = updated
        scheduleSave()
    }

    public func resetToDefaults() {
        guard settings != .default else { return }
        settings = .default
        scheduleSave()
    }

    /// Writes pending changes now, e.g. when the app moves to the background.
    public func flush() async {
        guard let saveTask else { return }
        saveTask.cancel()
        self.saveTask = nil
        try? await useCase.save(settings)
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [useCase, saveDelay] in
            try? await Task.sleep(for: saveDelay)
            guard !Task.isCancelled else { return }
            try? await useCase.save(self.settings)
            self.saveTask = nil
        }
    }
}
