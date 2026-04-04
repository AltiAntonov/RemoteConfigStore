//
//  RemoteConfigStoreErrorTests.swift
//  RemoteConfigStoreTests
//
//  Verifies the public store error surface and propagation behavior.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation
import Testing
@testable import RemoteConfigStore

struct RemoteConfigStoreErrorTests {
    @Test
    func cachedSnapshotThrowsWhenStoreIsEmpty() async throws {
        let fetcher = TestFetcher(result: .success(RemoteConfigSnapshot(values: [:])))
        let store = try makeStore(fetcher: fetcher)

        do {
            _ = try await store.cachedSnapshot()
            Issue.record("Expected empty store to throw noCachedSnapshot.")
        } catch let error as RemoteConfigStoreError {
            #expect(error == .noCachedSnapshot)
        }
    }

    @Test
    func snapshotPropagatesFetcherFailureWhenStoreIsEmpty() async throws {
        let fetcher = TestFetcher(result: .failure(.fetchFailed))
        let store = try makeStore(fetcher: fetcher)

        do {
            _ = try await store.snapshot(using: .immediate)
            Issue.record("Expected empty store to propagate the fetch failure.")
        } catch let error as TestError {
            #expect(error == .fetchFailed)
        }
    }

    @Test
    func refreshPropagatesFetcherFailure() async throws {
        let fetcher = TestFetcher(result: .failure(.fetchFailed))
        let store = try makeStore(fetcher: fetcher)

        do {
            _ = try await store.refresh()
            Issue.record("Expected refresh to propagate the fetch failure.")
        } catch let error as TestError {
            #expect(error == .fetchFailed)
        }
    }
}
