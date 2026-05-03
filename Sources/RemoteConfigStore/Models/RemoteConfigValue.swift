//
//  RemoteConfigValue.swift
//  RemoteConfigStore
//
//  Represents the value types supported by the store.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Represents the value types supported by the store.
public indirect enum RemoteConfigValue: Codable, Sendable, Equatable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case object([String: RemoteConfigValue])
    case array([RemoteConfigValue])
    case null

    /// The wrapped Boolean value, if this case stores one.
    public var boolValue: Bool? {
        guard case let .bool(value) = self else { return nil }
        return value
    }

    /// The wrapped integer value, if this case stores one.
    public var intValue: Int? {
        guard case let .int(value) = self else { return nil }
        return value
    }

    /// The wrapped floating-point value, if this case stores one.
    public var doubleValue: Double? {
        guard case let .double(value) = self else { return nil }
        return value
    }

    /// The wrapped string value, if this case stores one.
    public var stringValue: String? {
        guard case let .string(value) = self else { return nil }
        return value
    }

    /// The wrapped object value, if this case stores one.
    public var objectValue: [String: RemoteConfigValue]? {
        guard case let .object(value) = self else { return nil }
        return value
    }

    /// The wrapped array value, if this case stores one.
    public var arrayValue: [RemoteConfigValue]? {
        guard case let .array(value) = self else { return nil }
        return value
    }

    /// Returns whether this value represents a JSON `null`.
    public var isNull: Bool {
        self == .null
    }

    var jsonObject: Any {
        switch self {
        case .bool(let value):
            return value
        case .int(let value):
            return value
        case .double(let value):
            return value
        case .string(let value):
            return value
        case .object(let value):
            return value.mapValues(\.jsonObject)
        case .array(let value):
            return value.map(\.jsonObject)
        case .null:
            return NSNull()
        }
    }
}
