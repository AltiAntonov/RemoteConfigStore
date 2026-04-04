//
//  RemoteConfigSnapshot.swift
//  RemoteConfigStore
//
//  Captures one fetched set of remote config values.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

public struct RemoteConfigSnapshot: Codable, Sendable, Equatable {
    public let values: [String: RemoteConfigValue]
    public let fetchedAt: Date

    public init(values: [String: RemoteConfigValue], fetchedAt: Date = Date()) {
        self.values = values
        self.fetchedAt = fetchedAt
    }

    public func value(for key: String) -> RemoteConfigValue? {
        values[key]
    }
}
