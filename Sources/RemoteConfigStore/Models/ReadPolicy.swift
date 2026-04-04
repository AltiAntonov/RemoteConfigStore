//
//  ReadPolicy.swift
//  RemoteConfigStore
//
//  Describes how cached reads interact with refresh behavior.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Describes how cached values should be balanced against refresh work.
public enum ReadPolicy: Sendable, Equatable {
    /// Returns any usable cached value immediately, refreshing only when nothing usable exists.
    case immediate
    /// Attempts a refresh before returning stale cached data.
    case refreshBeforeReturning
    /// Returns usable cached data immediately while scheduling a background refresh.
    case immediateWithBackgroundRefresh
}
