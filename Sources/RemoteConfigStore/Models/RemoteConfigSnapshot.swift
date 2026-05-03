//
//  RemoteConfigSnapshot.swift
//  RemoteConfigStore
//
//  Captures one fetched set of remote config values.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Captures one fetched set of remote configuration values.
public struct RemoteConfigSnapshot: Codable, Sendable, Equatable {
    /// The raw values keyed by their remote configuration names.
    public let values: [String: RemoteConfigValue]
    /// The time when the snapshot was fetched from its remote source.
    public let fetchedAt: Date
    /// HTTP response metadata that can be reused for conditional fetch validation.
    public let httpValidationMetadata: HTTPRemoteConfigValidationMetadata?

    /// Creates a snapshot from raw values and their fetch time.
    ///
    /// - Parameters:
    ///   - values: The remote configuration values keyed by name.
    ///   - fetchedAt: The time when the snapshot was fetched.
    ///   - httpValidationMetadata: Persisted HTTP validation metadata for conditional requests.
    public init(
        values: [String: RemoteConfigValue],
        fetchedAt: Date = Date(),
        httpValidationMetadata: HTTPRemoteConfigValidationMetadata? = nil
    ) {
        self.values = values
        self.fetchedAt = fetchedAt
        self.httpValidationMetadata = httpValidationMetadata
    }

    /// Returns the raw value stored for a given key name.
    ///
    /// - Parameter key: The raw key name to look up.
    /// - Returns: The stored value, if one exists.
    public func value(for key: String) -> RemoteConfigValue? {
        values[key]
    }

    /// Returns a Boolean value for the supplied typed key.
    ///
    /// - Parameter key: The typed key to resolve.
    /// - Returns: The stored value or the key's default value.
    public func bool(for key: RemoteConfigKey<Bool>) -> Bool {
        value(for: key, defaultingTo: \.boolValue)
    }

    /// Returns an integer value for the supplied typed key.
    ///
    /// - Parameter key: The typed key to resolve.
    /// - Returns: The stored value or the key's default value.
    public func int(for key: RemoteConfigKey<Int>) -> Int {
        value(for: key, defaultingTo: \.intValue)
    }

    /// Returns a floating-point value for the supplied typed key.
    ///
    /// - Parameter key: The typed key to resolve.
    /// - Returns: The stored value or the key's default value.
    public func double(for key: RemoteConfigKey<Double>) -> Double {
        value(for: key, defaultingTo: \.doubleValue)
    }

    /// Returns a string value for the supplied typed key.
    ///
    /// - Parameter key: The typed key to resolve.
    /// - Returns: The stored value or the key's default value.
    public func string(for key: RemoteConfigKey<String>) -> String {
        value(for: key, defaultingTo: \.stringValue)
    }

    /// Decodes a stored value into a consumer-defined type.
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type to create.
    ///   - key: The raw key name to decode from.
    /// - Returns: The decoded value.
    /// - Throws: `RemoteConfigDecodingError` when the key is missing or decoding fails.
    public func decodedValue<Value: Decodable>(
        _ type: Value.Type = Value.self,
        for key: String
    ) throws -> Value {
        guard let value = value(for: key) else {
            throw RemoteConfigDecodingError.missingValue(key: key)
        }

        do {
            let data = try JSONSerialization.data(
                withJSONObject: value.jsonObject,
                options: [.fragmentsAllowed]
            )
            return try JSONDecoder().decode(type, from: data)
        } catch let error as DecodingError {
            throw RemoteConfigDecodingError.decodingFailed(
                key: key,
                description: String(describing: error)
            )
        } catch {
            throw RemoteConfigDecodingError.invalidJSONValue(key: key)
        }
    }

    /// Returns the snapshot age in seconds relative to the supplied reference date.
    ///
    /// - Parameter now: The date used as the comparison point.
    /// - Returns: The number of seconds since the snapshot was fetched.
    public func age(relativeTo now: Date = Date()) -> TimeInterval {
        max(0, now.timeIntervalSince(fetchedAt))
    }

    /// Returns the freshness state for the supplied cache policy windows.
    ///
    /// - Parameters:
    ///   - ttl: The duration for which the snapshot is considered fresh.
    ///   - maxStaleAge: The optional additional duration in which stale data remains usable.
    ///   - now: The date used as the comparison point.
    /// - Returns: The snapshot freshness state at the supplied point in time.
    public func freshness(
        ttl: TimeInterval,
        maxStaleAge: TimeInterval? = nil,
        relativeTo now: Date = Date()
    ) -> SnapshotFreshness {
        let snapshotAge = age(relativeTo: now)
        if snapshotAge <= ttl {
            return .fresh
        }

        if let maxStaleAge, snapshotAge <= ttl + maxStaleAge {
            return .stale
        }

        return .expired
    }

    /// Returns whether this snapshot has the same configuration payload as another snapshot.
    ///
    /// `fetchedAt` is intentionally ignored so refresh work can distinguish payload changes
    /// from freshness renewal.
    ///
    /// - Parameter other: The snapshot to compare against.
    /// - Returns: `true` when both snapshots contain the same keyed values.
    public func hasSamePayload(as other: RemoteConfigSnapshot) -> Bool {
        values == other.values
    }

    private func value<Value>(
        for key: RemoteConfigKey<Value>,
        defaultingTo projection: KeyPath<RemoteConfigValue, Value?>
    ) -> Value {
        values[key.name]?[keyPath: projection] ?? key.defaultValue
    }
}
