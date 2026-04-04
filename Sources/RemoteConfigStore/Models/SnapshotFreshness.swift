//
//  SnapshotFreshness.swift
//  RemoteConfigStore
//
//  Describes the freshness state of a cached snapshot.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Describes how a snapshot relates to its freshness windows.
public enum SnapshotFreshness: Sendable, Equatable {
    /// The snapshot is still within its time-to-live window.
    case fresh
    /// The snapshot is past its TTL but still within the configured stale fallback window.
    case stale
    /// The snapshot is too old to be served as a fallback.
    case expired
}
