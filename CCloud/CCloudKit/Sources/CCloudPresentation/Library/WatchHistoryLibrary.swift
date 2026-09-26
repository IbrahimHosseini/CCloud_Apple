import CCloudDomain
import Foundation
import Observation

/// Which episodes were watched, shared by the series pages, the player and Settings.
@MainActor
@Observable
public final class WatchHistoryLibrary {
    public private(set) var history: WatchHistory = .empty
    public private(set) var isLoaded = false

    @ObservationIgnored private let useCase: WatchHistoryUseCase
    @ObservationIgnored private let now: @Sendable () -> Date
    @ObservationIgnored private var pendingSave: Task<Void, Never>?

    public init(useCase: WatchHistoryUseCase, now: @escaping @Sendable () -> Date = Date.init) {
        self.useCase = useCase
        self.now = now
    }

    public func load() async {
        guard !isLoaded else { return }
        history = await useCase.load()
        isLoaded = true
    }

    public func isWatched(_ episode: EpisodeReference) -> Bool {
        history.isWatched(episode)
    }

    public func markWatched(_ episode: EpisodeReference) {
        var updated = history
        updated.markWatched(episode, at: now())
        commit(updated)
    }

    public func markUnwatched(_ episode: EpisodeReference) {
        var updated = history
        updated.markUnwatched(episode)
        commit(updated)
    }

    public func removeAll() {
        var updated = history
        updated.removeAll()
        commit(updated)
    }

    /// Bytes on disk, once pending saves are written.
    public func storageSize() async -> Int {
        await pendingSave?.value
        return await useCase.storageSize()
    }

    private func commit(_ updated: WatchHistory) {
        guard updated != history else { return }
        history = updated
        let previous = pendingSave
        pendingSave = Task { [useCase] in
            await previous?.value
            try? await useCase.save(self.history)
        }
    }
}
