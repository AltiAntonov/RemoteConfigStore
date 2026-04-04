import Foundation

public protocol RemoteConfigFetcher: Sendable {
    func fetch() async throws -> RemoteConfigSnapshot
}
