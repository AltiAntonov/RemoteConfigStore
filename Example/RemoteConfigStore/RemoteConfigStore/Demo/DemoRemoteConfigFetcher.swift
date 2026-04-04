//
//  DemoRemoteConfigFetcher.swift
//  RemoteConfigStore
//
//  Simulates a remote configuration backend for the example app.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation
import RemoteConfigStore

/// Simulates a remote backend whose configuration revision can be advanced locally.
actor DemoRemoteConfigFetcher: RemoteConfigFetcher {
    private(set) var fetchCount = 0
    private var revision = 1
    private let simulatedNetworkDelay: UInt64 = 600_000_000

    /// Advances the simulated remote revision so the next fetch returns newer values.
    func advanceRevision() {
        revision += 1
    }

    /// Returns the current simulated remote revision.
    func currentRevision() -> Int {
        revision
    }

    /// Returns the number of times the demo backend has been queried.
    func currentFetchCount() -> Int {
        fetchCount
    }

    /// Fetches the current demo snapshot after a short delay.
    func fetchSnapshot() async throws -> RemoteConfigSnapshot {
        fetchCount += 1
        try await Task.sleep(nanoseconds: simulatedNetworkDelay)
        return RemoteConfigSnapshot(values: Self.makeValues(for: revision))
    }

    private static func makeValues(for revision: Int) -> [String: RemoteConfigValue] {
        [
            "config_revision": .int(revision),
            "feature.new_ui": .bool(revision >= 2),
            "welcome_message": .string(revision >= 2 ? "Fresh config is now active." : "Cached config is being served."),
            "request_timeout_ms": .int(revision >= 3 ? 750 : 1200),
            "rollout_fraction": .double(revision >= 3 ? 0.65 : 0.25)
        ]
    }
}
