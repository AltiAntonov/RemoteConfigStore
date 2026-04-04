//
//  RemoteConfigFetcher.swift
//  RemoteConfigStore
//
//  Loads fresh config snapshots for the store.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Loads a fresh remote configuration snapshot.
public protocol RemoteConfigFetcher: Sendable {
    /// Fetches the latest snapshot from the remote source.
    ///
    /// - Returns: A freshly fetched configuration snapshot.
    /// - Throws: An error describing why the fetch failed.
    func fetchSnapshot() async throws -> RemoteConfigSnapshot
}
