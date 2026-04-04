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

    /// Creates a snapshot from raw values and their fetch time.
    ///
    /// - Parameters:
    ///   - values: The remote configuration values keyed by name.
    ///   - fetchedAt: The time when the snapshot was fetched.
    public init(values: [String: RemoteConfigValue], fetchedAt: Date = Date()) {
        self.values = values
        self.fetchedAt = fetchedAt
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

    private func value<Value>(
        for key: RemoteConfigKey<Value>,
        defaultingTo projection: KeyPath<RemoteConfigValue, Value?>
    ) -> Value {
        values[key.name]?[keyPath: projection] ?? key.defaultValue
    }
}
