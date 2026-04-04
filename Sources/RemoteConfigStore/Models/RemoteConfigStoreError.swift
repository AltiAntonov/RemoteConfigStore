//
//  RemoteConfigStoreError.swift
//  RemoteConfigStore
//
//  Defines the store-specific error surface.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Describes the store-specific errors currently surfaced by `RemoteConfigStore`.
public enum RemoteConfigStoreError: Error, Equatable, Sendable {
    /// Indicates that neither memory nor disk cache contains a snapshot.
    case noCachedSnapshot
}
