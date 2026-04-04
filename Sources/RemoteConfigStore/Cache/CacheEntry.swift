//
//  CacheEntry.swift
//  RemoteConfigStore
//
//  Caches a value together with its expiration timestamp.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

public struct CacheEntry<Value: Codable & Sendable & Equatable>: Codable, Sendable, Equatable {
    public let value: Value
    public let expirationDate: Date

    public init(value: Value, expirationDate: Date) {
        self.value = value
        self.expirationDate = expirationDate
    }
}
