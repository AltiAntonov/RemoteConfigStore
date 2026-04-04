//
//  CacheEntry.swift
//  RemoteConfigStore
//
//  Caches a value together with its expiration timestamp.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Stores a cached value together with its expiration timestamp.
public struct CacheEntry<Value: Codable & Sendable & Equatable>: Codable, Sendable, Equatable {
    /// The cached value.
    public let value: Value
    /// The time when the cached value should stop being considered fresh.
    public let expirationDate: Date

    /// Creates a cache entry for a value and its expiration timestamp.
    ///
    /// - Parameters:
    ///   - value: The cached value.
    ///   - expirationDate: The freshness cutoff for the value.
    public init(value: Value, expirationDate: Date) {
        self.value = value
        self.expirationDate = expirationDate
    }
}
