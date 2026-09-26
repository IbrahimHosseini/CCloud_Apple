import Foundation

/// Stores small blobs by key. Local repositories encode their data into it as JSON.
///
/// Which implementation is used is decided by the composition root: tvOS apps may only keep
/// data in `UserDefaults` (their files can be purged), iOS and macOS use files.
public protocol KeyValueStorage: Sendable {
    func data(forKey key: String) async throws -> Data?
    /// Stores `data`, or deletes the key when `data` is `nil`.
    func setData(_ data: Data?, forKey key: String) async throws
}

/// One JSON file per key in Application Support.
public actor FileStorage: KeyValueStorage {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    /// `<Application Support>/<folderName>`.
    public static func applicationSupport(folderName: String) -> FileStorage {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return FileStorage(directory: base.appending(path: folderName, directoryHint: .isDirectory))
    }

    public func data(forKey key: String) throws -> Data? {
        let url = fileURL(for: key)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return nil }
        return try Data(contentsOf: url)
    }

    public func setData(_ data: Data?, forKey key: String) throws {
        let url = fileURL(for: key)
        guard let data else {
            if FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
                try FileManager.default.removeItem(at: url)
            }
            return
        }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }

    private func fileURL(for key: String) -> URL {
        directory.appending(path: "\(key).json", directoryHint: .notDirectory)
    }
}

/// Values in a `UserDefaults` suite.
public actor UserDefaultsStorage: KeyValueStorage {
    private let defaults: UserDefaults
    private let prefix: String

    /// `suiteName` `nil` uses the standard defaults.
    public init(suiteName: String? = nil, keyPrefix: String = "ccloud.") {
        defaults = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
        prefix = keyPrefix
    }

    public func data(forKey key: String) -> Data? {
        defaults.data(forKey: prefix + key)
    }

    public func setData(_ data: Data?, forKey key: String) {
        if let data {
            defaults.set(data, forKey: prefix + key)
        } else {
            defaults.removeObject(forKey: prefix + key)
        }
    }
}

/// Keeps values in memory only. For demos, previews and tests.
public actor InMemoryStorage: KeyValueStorage {
    private var values: [String: Data] = [:]

    public init() {}

    public func data(forKey key: String) -> Data? {
        values[key]
    }

    public func setData(_ data: Data?, forKey key: String) {
        values[key] = data
    }
}
