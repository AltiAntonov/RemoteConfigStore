import Foundation

public enum RemoteConfigStoreError: Error, Equatable, Sendable {
    case noCachedSnapshot
    case noUsableCachedSnapshot
    case missingValue(String)
    case typeMismatch(String)
}
