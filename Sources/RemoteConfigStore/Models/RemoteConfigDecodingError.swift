//
//  RemoteConfigDecodingError.swift
//  RemoteConfigStore
//
//  Defines structured value decoding failures.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Describes failures that can occur when decoding a stored remote config value.
public enum RemoteConfigDecodingError: Error, Equatable, Sendable {
    /// Indicates that no value exists for the requested key.
    case missingValue(key: String)
    /// Indicates that the stored value could not be converted into JSON data.
    case invalidJSONValue(key: String)
    /// Indicates that JSON decoding failed for the requested key.
    case decodingFailed(key: String, description: String)
}
