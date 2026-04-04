//
//  RemoteConfigStoreBehaviorTests.swift
//  RemoteConfigStoreTests
//
//  Verifies loading, stale fallback, and typed reads in the store.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation
import Testing
@testable import RemoteConfigStore

struct RemoteConfigStoreBehaviorTests {
    @Test
    func loadReturnsFreshMemorySnapshotBeforeHittingNetwork() async throws {
        let fetcher = TestFetcher(result: .success(RemoteConfigSnapshot(values: ["new_ui": .bool(false)])))
        let store = try makeStore(fetcher: fetcher)
        let cached = RemoteConfigSnapshot(values: ["new_ui": .bool(true)], fetchedAt: Date())

        try await store.seedSnapshot(cached)

        let loaded = try await store.snapshot(using: .immediate)
        let fetchCount = await fetcher.fetchCount

        #expect(loaded == cached)
        #expect(fetchCount == 0)
    }

    @Test
    func loadReturnsStaleSnapshotWhenWithinMaxStaleAndRefreshFails() async throws {
        let fetcher = TestFetcher(result: .failure(.fetchFailed))
        let store = try makeStore(fetcher: fetcher, ttl: 1, maxStaleAge: 60)
        let stale = RemoteConfigSnapshot(values: ["new_ui": .bool(true)], fetchedAt: Date().addingTimeInterval(-10))

        try await store.seedSnapshot(stale, fetchedAt: Date().addingTimeInterval(-10))

        let loaded = try await store.snapshot(using: .refreshBeforeReturning)

        #expect(loaded.values["new_ui"] == .bool(true))
    }

    @Test
    func valueReturnsTypedDefaultWhenKeyMissing() async throws {
        let fetcher = TestFetcher(result: .success(RemoteConfigSnapshot(values: [:])))
        let store = try makeStore(fetcher: fetcher)
        let key = RemoteConfigKey<Bool>("new_ui", defaultValue: false)

        let value = try await store.value(for: key, using: .refreshBeforeReturning)

        #expect(value == false)
    }

    @Test
    func refreshSharesOneInFlightFetchAcrossConcurrentCallers() async throws {
        let fetcher = ControlledFetcher()
        let store = try makeStore(fetcher: fetcher)
        let fresh = RemoteConfigSnapshot(values: ["new_ui": .bool(true)])

        async let first = store.refresh()
        async let second = store.refresh()

        await fetcher.waitForFetchStart()
        let fetchCountBeforeCompletion = await fetcher.fetchCount

        await fetcher.succeed(with: fresh)

        let firstSnapshot = try await first
        let secondSnapshot = try await second
        let finalFetchCount = await fetcher.fetchCount

        #expect(fetchCountBeforeCompletion == 1)
        #expect(finalFetchCount == 1)
        #expect(firstSnapshot == fresh)
        #expect(secondSnapshot == fresh)
    }

    @Test
    func immediateWithBackgroundRefreshReturnsStaleSnapshotAndUpdatesCache() async throws {
        let fetcher = ControlledFetcher()
        let store = try makeStore(fetcher: fetcher, ttl: 1, maxStaleAge: 60)
        let stale = RemoteConfigSnapshot(values: ["new_ui": .bool(false)], fetchedAt: Date().addingTimeInterval(-10))
        let fresh = RemoteConfigSnapshot(values: ["new_ui": .bool(true)])

        try await store.seedSnapshot(stale, fetchedAt: stale.fetchedAt)

        let loaded = try await store.snapshot(using: .immediateWithBackgroundRefresh)

        await fetcher.waitForFetchStart()
        let fetchCountBeforeCompletion = await fetcher.fetchCount
        await fetcher.succeed(with: fresh)

        try await waitUntil {
            let cached = try await store.cachedSnapshot()
            return cached == fresh
        }

        let cachedSnapshot = try await store.cachedSnapshot()

        #expect(loaded == stale)
        #expect(fetchCountBeforeCompletion == 1)
        #expect(cachedSnapshot == fresh)
    }

    @Test
    func snapshotRefreshesWhenDiskCacheIsCorrupted() async throws {
        let fresh = RemoteConfigSnapshot(values: ["new_ui": .bool(true)])
        let fetcher = TestFetcher(result: .success(fresh))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let fileURL = directory.appendingPathComponent("default.json")
        let store = try RemoteConfigStore(
            fetcher: fetcher,
            cacheDirectory: directory,
            ttl: 60
        )

        try Data("not-json".utf8).write(to: fileURL, options: .atomic)

        let loaded = try await store.snapshot(using: .immediate)
        let fetchCount = await fetcher.fetchCount

        #expect(loaded == fresh)
        #expect(fetchCount == 1)
    }
}
