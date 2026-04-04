//
//  MemoryCache.swift
//  RemoteConfigStore
//
//  Stores cached snapshots in memory behind actor isolation.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

actor MemoryCache<Key: Hashable & Sendable, Value: Codable & Sendable & Equatable> {
    private var storage: [Key: CacheEntry<Value>] = [:]

    init() {}

    func entry(for key: Key) -> CacheEntry<Value>? {
        storage[key]
    }

    func set(_ entry: CacheEntry<Value>, for key: Key) {
        storage[key] = entry
    }

    func removeValue(for key: Key) {
        storage.removeValue(forKey: key)
    }
}
