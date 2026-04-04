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
}
