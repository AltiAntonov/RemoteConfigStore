//
//  RemoteConfigStoreError.swift
//  RemoteConfigStore
//
//  Defines store-level errors for cache and lookup failures.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

public enum RemoteConfigStoreError: Error, Equatable, Sendable {
    case noCachedSnapshot
    case noUsableCachedSnapshot
    case missingValue(String)
    case typeMismatch(String)
}
