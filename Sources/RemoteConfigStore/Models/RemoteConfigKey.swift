//
//  RemoteConfigKey.swift
//  RemoteConfigStore
//
//  Defines a typed key and default value for remote config access.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Defines a typed remote configuration key and its fallback value.
public struct RemoteConfigKey<Value: Sendable>: Sendable {
    /// The raw name used to look up the value inside a snapshot.
    public let name: String
    /// The fallback value returned when the key is missing or has the wrong shape.
    public let defaultValue: Value

    /// Creates a typed remote configuration key.
    ///
    /// - Parameters:
    ///   - name: The raw key name stored in the remote configuration payload.
    ///   - defaultValue: The value returned when the key is unavailable.
    public init(_ name: String, defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }
}
