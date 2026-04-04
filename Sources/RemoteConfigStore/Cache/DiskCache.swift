import Foundation

public struct DiskCache: Sendable {
    private let directory: URL

    public init(directory: URL) throws {
        self.directory = directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public func save(_ entry: CacheEntry<RemoteConfigSnapshot>, for key: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(entry)
        try data.write(to: fileURL(for: key), options: .atomic)
    }

    public func load(for key: String) throws -> CacheEntry<RemoteConfigSnapshot>? {
        let url = fileURL(for: key)
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        let decoder = JSONDecoder()
        let data = try Data(contentsOf: url)
        return try decoder.decode(CacheEntry<RemoteConfigSnapshot>.self, from: data)
    }

    private func fileURL(for key: String) -> URL {
        directory.appendingPathComponent("\(key).json")
    }
}
