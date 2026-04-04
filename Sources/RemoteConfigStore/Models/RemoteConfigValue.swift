//
//  RemoteConfigValue.swift
//  RemoteConfigStore
//
//  Represents the primitive value types supported by the store.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

public enum RemoteConfigValue: Codable, Sendable, Equatable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)

    public var boolValue: Bool? {
        guard case let .bool(value) = self else { return nil }
        return value
    }

    public var intValue: Int? {
        guard case let .int(value) = self else { return nil }
        return value
    }

    public var doubleValue: Double? {
        guard case let .double(value) = self else { return nil }
        return value
    }

    public var stringValue: String? {
        guard case let .string(value) = self else { return nil }
        return value
    }
}
