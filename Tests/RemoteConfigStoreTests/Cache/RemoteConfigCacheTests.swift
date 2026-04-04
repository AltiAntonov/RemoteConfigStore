//
//  RemoteConfigCacheTests.swift
//  RemoteConfigStoreTests
//
//  Verifies cache entry freshness and cache persistence behavior.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation
import Testing
@testable import RemoteConfigStore

struct RemoteConfigCacheTests {
    @Test
    func ttlPolicySeparatesFreshStaleAndExpiredBeyondMaxStale() {
        let now = Date(timeIntervalSince1970: 200)
        let freshEntry = CacheEntry(
            value: RemoteConfigSnapshot(values: [:], fetchedAt: Date(timeIntervalSince1970: 150)),
            expirationDate: Date(timeIntervalSince1970: 250)
        )
        let staleEntry = CacheEntry(
            value: RemoteConfigSnapshot(values: [:], fetchedAt: Date(timeIntervalSince1970: 100)),
            expirationDate: Date(timeIntervalSince1970: 150)
        )
        let policy = TTLPolicy(ttl: 60, maxStaleAge: 120)
        let expiredEntry = CacheEntry(
            value: RemoteConfigSnapshot(values: [:], fetchedAt: Date(timeIntervalSince1970: 0)),
            expirationDate: Date(timeIntervalSince1970: 10)
        )

        #expect(policy.isFresh(freshEntry, now: now))
        #expect(policy.isWithinMaxStaleAge(staleEntry, now: now))
        #expect(policy.isUsable(expiredEntry, now: now) == false)
    }

    @Test
    func memoryCacheStoresAndReturnsEntry() async {
        let cache = MemoryCache<String, RemoteConfigSnapshot>()
        let entry = CacheEntry(
            value: RemoteConfigSnapshot(values: ["new_ui": .bool(true)]),
            expirationDate: Date().addingTimeInterval(60)
        )

        await cache.set(entry, for: "default")
        let loaded = await cache.entry(for: "default")

        #expect(loaded == entry)
    }

    @Test
    func diskCachePersistsEntryToDisk() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cache = try DiskCache(directory: directory)
        let entry = CacheEntry(
            value: RemoteConfigSnapshot(values: ["new_ui": .bool(true)]),
            expirationDate: Date(timeIntervalSince1970: 500)
        )

        try cache.save(entry, for: "default")
        let loaded = try cache.load(for: "default")

        #expect(loaded == entry)
    }

    @Test
    func diskCacheTreatsCorruptedSnapshotAsCacheMissAndRemovesFile() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cache = try DiskCache(directory: directory)
        let fileURL = directory.appendingPathComponent("default.json")

        try Data("not-json".utf8).write(to: fileURL, options: .atomic)

        let loaded = try cache.load(for: "default")
        let fileStillExists = FileManager.default.fileExists(atPath: fileURL.path)

        #expect(loaded == nil)
        #expect(fileStillExists == false)
    }
}
