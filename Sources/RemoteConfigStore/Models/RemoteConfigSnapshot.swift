import Foundation

public struct RemoteConfigSnapshot: Codable, Sendable, Equatable {
    public let values: [String: RemoteConfigValue]
    public let fetchedAt: Date

    public init(values: [String: RemoteConfigValue], fetchedAt: Date = Date()) {
        self.values = values
        self.fetchedAt = fetchedAt
    }

    public func value(for key: String) -> RemoteConfigValue? {
        values[key]
    }
}
