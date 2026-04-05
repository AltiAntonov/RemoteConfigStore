//
//  RemoteConfigRefreshResult.swift
//  RemoteConfigStore
//
//  Describes whether a refresh changed the remote config payload.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Describes whether a refresh produced a new payload or confirmed the existing one.
public enum RemoteConfigRefreshResult: Sendable, Equatable {
    /// The fetched snapshot differs from the cached payload or there was no cached snapshot.
    case updated(RemoteConfigSnapshot)
    /// The fetched snapshot matches the cached payload, but freshness is renewed.
    case unchanged(RemoteConfigSnapshot)

    /// The snapshot associated with the refresh result.
    public var snapshot: RemoteConfigSnapshot {
        switch self {
        case .updated(let snapshot), .unchanged(let snapshot):
            snapshot
        }
    }
}
