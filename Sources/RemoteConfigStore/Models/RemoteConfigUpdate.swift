//
//  RemoteConfigUpdate.swift
//  RemoteConfigStore
//
//  Describes a refresh event emitted by the store.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Describes a refresh event emitted by `RemoteConfigStore`.
public struct RemoteConfigUpdate: Sendable, Equatable {
    /// The refresh result that produced the update.
    public let result: RemoteConfigRefreshResult

    /// The snapshot associated with the refresh result.
    public var snapshot: RemoteConfigSnapshot {
        result.snapshot
    }

    /// Creates a store update event.
    ///
    /// - Parameter result: The refresh result that produced the update.
    public init(result: RemoteConfigRefreshResult) {
        self.result = result
    }
}
