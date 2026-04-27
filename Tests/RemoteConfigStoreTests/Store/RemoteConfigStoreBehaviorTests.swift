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

    @Test
    func convenienceAccessorsReturnPrimitiveValuesForTypedKeys() async throws {
        let snapshot = RemoteConfigSnapshot(values: [
            "feature.new_ui": .bool(true),
            "welcome_message": .string("Hello"),
            "request_timeout_ms": .int(5000),
            "rollout_fraction": .double(0.25)
        ])
        let fetcher = TestFetcher(result: .success(snapshot))
        let store = try makeStore(fetcher: fetcher)

        let boolValue = try await store.bool(for: .init("feature.new_ui", defaultValue: false))
        let stringValue = try await store.string(for: .init("welcome_message", defaultValue: "Fallback"))
        let intValue = try await store.int(for: .init("request_timeout_ms", defaultValue: 1000))
        let doubleValue = try await store.double(for: .init("rollout_fraction", defaultValue: 1.0))

        #expect(boolValue == true)
        #expect(stringValue == "Hello")
        #expect(intValue == 5000)
        #expect(doubleValue == 0.25)
    }

    @Test
    func convenienceInitializerBuildsStoreFromHTTPRequest() async throws {
        let cacheDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let url = try #require(URL(string: "https://example.com/config"))

        let store = try RemoteConfigStore(
            request: HTTPRemoteConfigRequest(
                url: url,
                headers: ["Authorization": "Bearer token"],
                timeoutInterval: 12
            ),
            cacheDirectory: cacheDirectory,
            ttl: 60
        )

        let cachedSnapshot = await #expect(throws: RemoteConfigStoreError.noCachedSnapshot) {
            try await store.cachedSnapshot()
        }
        _ = cachedSnapshot
    }

    @Test
    func refreshResultReportsUpdatedWhenNoCachedSnapshotExists() async throws {
        let fresh = RemoteConfigSnapshot(values: ["new_ui": .bool(true)])
        let fetcher = TestFetcher(result: .success(fresh))
        let store = try makeStore(fetcher: fetcher)

        let result = try await store.refreshResult()

        switch result {
        case .updated(let snapshot):
            #expect(snapshot == fresh)
        case .unchanged:
            Issue.record("Expected an updated refresh result when no cached snapshot exists.")
        }
    }

    @Test
    func refreshResultReportsUnchangedWhenFetchedPayloadMatchesCachedSnapshot() async throws {
        let cached = RemoteConfigSnapshot(
            values: ["new_ui": .bool(true), "config_revision": .int(1)],
            fetchedAt: Date().addingTimeInterval(-120)
        )
        let fetched = RemoteConfigSnapshot(
            values: ["new_ui": .bool(true), "config_revision": .int(1)],
            fetchedAt: Date()
        )
        let fetcher = TestFetcher(result: .success(fetched))
        let store = try makeStore(fetcher: fetcher)

        try await store.seedSnapshot(cached, fetchedAt: cached.fetchedAt)

        let result = try await store.refreshResult()
        let cachedAfterRefresh = try await store.cachedSnapshot()

        switch result {
        case .unchanged(let snapshot):
            #expect(snapshot == fetched)
            #expect(cachedAfterRefresh == fetched)
        case .updated:
            Issue.record("Expected an unchanged refresh result when payload values match.")
        }
    }

    @Test
    func refreshResultReportsUpdatedWhenFetchedPayloadChanges() async throws {
        let cached = RemoteConfigSnapshot(
            values: ["new_ui": .bool(false), "config_revision": .int(1)],
            fetchedAt: Date().addingTimeInterval(-120)
        )
        let fetched = RemoteConfigSnapshot(
            values: ["new_ui": .bool(true), "config_revision": .int(2)],
            fetchedAt: Date()
        )
        let fetcher = TestFetcher(result: .success(fetched))
        let store = try makeStore(fetcher: fetcher)

        try await store.seedSnapshot(cached, fetchedAt: cached.fetchedAt)

        let result = try await store.refreshResult()

        switch result {
        case .updated(let snapshot):
            #expect(snapshot == fetched)
        case .unchanged:
            Issue.record("Expected an updated refresh result when payload values change.")
        }
    }

    @Test
    func updatesStreamEmitsRefreshEvents() async throws {
        let fresh = RemoteConfigSnapshot(values: ["new_ui": .bool(true)])
        let fetcher = TestFetcher(result: .success(fresh))
        let store = try makeStore(fetcher: fetcher)
        let updates = await store.updates()

        let updateTask = Task {
            var iterator = updates.makeAsyncIterator()
            return await iterator.next()
        }

        let result = try await store.refreshResult()
        let update = try #require(await updateTask.value)

        #expect(update.result == result)
        #expect(update.snapshot == fresh)
    }

    @Test
    func inspectionStateReportsCachedSnapshotFreshnessAndRefreshActivity() async throws {
        let fetcher = ControlledFetcher()
        let store = try makeStore(fetcher: fetcher, ttl: 60)
        let cached = RemoteConfigSnapshot(
            values: ["new_ui": .bool(true)],
            fetchedAt: Date()
        )

        try await store.seedSnapshot(cached)

        async let refresh = store.refresh()
        await fetcher.waitForFetchStart()

        let stateDuringRefresh = try await store.inspectionState()
        await fetcher.succeed(with: RemoteConfigSnapshot(values: ["new_ui": .bool(false)]))
        _ = try await refresh
        let stateAfterRefresh = try await store.inspectionState()

        #expect(stateDuringRefresh.snapshot == cached)
        #expect(stateDuringRefresh.freshness == .fresh)
        #expect(stateDuringRefresh.isRefreshInFlight)
        #expect(stateAfterRefresh.snapshot?.values["new_ui"] == .bool(false))
        #expect(stateAfterRefresh.isRefreshInFlight == false)
    }

    @Test
    func refreshResultReturnsUnchangedWhenHTTPFetcherReceivesNotModifiedResponse() async throws {
        StoreHTTPMockURLProtocol.setRequestHandler { request in
            #expect(request.value(forHTTPHeaderField: "If-None-Match") == #""config-v1""#)

            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 304,
                httpVersion: nil,
                headerFields: ["ETag": #""config-v2""#]
            )!
            return (response, Data())
        }

        defer { StoreHTTPMockURLProtocol.setRequestHandler(nil) }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StoreHTTPMockURLProtocol.self]
        let mockedSession = URLSession(configuration: configuration)
        let cached = RemoteConfigSnapshot(
            values: ["new_ui": .bool(true), "config_revision": .int(1)],
            fetchedAt: Date().addingTimeInterval(-120),
            httpValidationMetadata: HTTPRemoteConfigValidationMetadata(entityTag: #""config-v1""#)
        )
        let store = try RemoteConfigStore(
            request: HTTPRemoteConfigRequest(
                url: try #require(URL(string: "https://example.com/config"))
            ),
            cacheDirectory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            ttl: 60,
            session: mockedSession
        )

        try await store.seedSnapshot(cached, fetchedAt: cached.fetchedAt)

        let result = try await store.refreshResult()
        let cachedAfterRefresh = try await store.cachedSnapshot()

        switch result {
        case .unchanged(let snapshot):
            #expect(snapshot.values == cached.values)
            #expect(snapshot.fetchedAt > cached.fetchedAt)
            #expect(snapshot.httpValidationMetadata == HTTPRemoteConfigValidationMetadata(entityTag: #""config-v2""#))
            #expect(cachedAfterRefresh == snapshot)
        case .updated:
            Issue.record("Expected a not-modified HTTP response to reuse the cached payload.")
        }
    }
}

private final class StoreHTTPMockURLProtocol: URLProtocol, @unchecked Sendable {
    private static let storage = StoreHandlerStorage()

    static func setRequestHandler(
        _ handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?
    ) {
        storage.handler = handler
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.storage.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private final class StoreHandlerStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var _handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    var handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _handler
        }
        set {
            lock.lock()
            _handler = newValue
            lock.unlock()
        }
    }
}
