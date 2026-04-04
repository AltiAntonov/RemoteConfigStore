//
//  MemoryCache.swift
//  RemoteConfigStore
//
//  Stores cached snapshots in memory behind actor isolation.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

public actor MemoryCache<Key: Hashable & Sendable, Value: Codable & Sendable & Equatable> {
    private var storage: [Key: CacheEntry<Value>] = [:]

    public init() {}

    public func entry(for key: Key) -> CacheEntry<Value>? {
        storage[key]
    }

    public func set(_ entry: CacheEntry<Value>, for key: Key) {
        storage[key] = entry
    }

    public func removeValue(for key: Key) {
        storage.removeValue(forKey: key)
    }
}
