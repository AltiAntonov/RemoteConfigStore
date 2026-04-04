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
}
