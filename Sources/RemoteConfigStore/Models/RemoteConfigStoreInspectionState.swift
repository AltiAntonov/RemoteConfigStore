//
//  RemoteConfigStoreInspectionState.swift
//  RemoteConfigStore
//
//  Captures the store state useful for debugging and inspection.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Captures the current store state useful for debugging and inspection.
public struct RemoteConfigStoreInspectionState: Sendable, Equatable {
    /// The currently cached snapshot, if one exists.
    public let snapshot: RemoteConfigSnapshot?

    /// The freshness state of the cached snapshot, if one exists.
    public let freshness: SnapshotFreshness?

    /// Whether a refresh task is currently in flight.
    public let isRefreshInFlight: Bool

    /// Creates an inspection state snapshot.
    ///
    /// - Parameters:
    ///   - snapshot: The currently cached snapshot, if one exists.
    ///   - freshness: The freshness state of the cached snapshot, if one exists.
    ///   - isRefreshInFlight: Whether a refresh task is currently in flight.
    public init(
        snapshot: RemoteConfigSnapshot?,
        freshness: SnapshotFreshness?,
        isRefreshInFlight: Bool
    ) {
        self.snapshot = snapshot
        self.freshness = freshness
        self.isRefreshInFlight = isRefreshInFlight
    }
}
