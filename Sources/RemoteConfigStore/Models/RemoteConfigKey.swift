//
//  RemoteConfigKey.swift
//  RemoteConfigStore
//
//  Defines a typed key and default value for remote config access.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

public struct RemoteConfigKey<Value: Sendable>: Sendable {
    public let name: String
    public let defaultValue: Value

    public init(_ name: String, defaultValue: Value) {
        self.name = name
        self.defaultValue = defaultValue
    }
}
