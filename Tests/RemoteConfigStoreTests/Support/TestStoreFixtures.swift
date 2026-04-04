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

    func fetch() async throws -> RemoteConfigSnapshot {
        fetchCount += 1
        return try result.get()
    }
}

enum TestError: Error, Equatable {
    case fetchFailed
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
