//
//  RemoteConfigFetcher.swift
//  RemoteConfigStore
//
//  Loads fresh config snapshots for the store.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

public protocol RemoteConfigFetcher: Sendable {
    func fetch() async throws -> RemoteConfigSnapshot
}
