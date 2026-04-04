//
//  TestStoreFixtures.swift
//  RemoteConfigStoreTests
//
//  Provides shared fixtures for store-focused test suites.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation
@testable import RemoteConfigStore

actor TestFetcher: RemoteConfigFetcher {
    private(set) var fetchCount = 0
    private let result: Result<RemoteConfigSnapshot, TestError>

    init(result: Result<RemoteConfigSnapshot, TestError>) {
        self.result = result
    }

    func fetchSnapshot() async throws -> RemoteConfigSnapshot {
        fetchCount += 1
        return try result.get()
    }
}

actor ControlledFetcher: RemoteConfigFetcher {
    private(set) var fetchCount = 0
    private var pendingFetchContinuations: [CheckedContinuation<RemoteConfigSnapshot, Error>] = []
    private var fetchStartedContinuations: [CheckedContinuation<Void, Never>] = []

    func fetchSnapshot() async throws -> RemoteConfigSnapshot {
        fetchCount += 1
        resumeFetchStartedWaiters()

        return try await withCheckedThrowingContinuation { continuation in
            pendingFetchContinuations.append(continuation)
        }
    }

    func waitForFetchStart() async {
        if fetchCount > 0 {
            return
        }

        await withCheckedContinuation { continuation in
            fetchStartedContinuations.append(continuation)
        }
    }

    func succeed(with snapshot: RemoteConfigSnapshot) {
        let continuations = pendingFetchContinuations
        pendingFetchContinuations.removeAll()

        for continuation in continuations {
            continuation.resume(returning: snapshot)
        }
    }

    private func resumeFetchStartedWaiters() {
        let continuations = fetchStartedContinuations
        fetchStartedContinuations.removeAll()

        for continuation in continuations {
            continuation.resume()
        }
    }
}

enum TestError: Error, Equatable {
    case fetchFailed
    case conditionTimedOut
}

func makeStore(
    fetcher: some RemoteConfigFetcher,
    ttl: TimeInterval = 60,
    maxStaleAge: TimeInterval? = nil
) throws -> RemoteConfigStore {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    return try RemoteConfigStore(
        fetcher: fetcher,
        cacheDirectory: directory,
        ttl: ttl,
        maxStaleAge: maxStaleAge
    )
}

func waitUntil(
    timeoutNanoseconds: UInt64 = 1_000_000_000,
    condition: @escaping @Sendable () async throws -> Bool
) async throws {
    let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds

    while DispatchTime.now().uptimeNanoseconds < deadline {
        if try await condition() {
            return
        }

        await Task.yield()
    }

    throw TestError.conditionTimedOut
}
