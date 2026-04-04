//
//  TTLPolicy.swift
//  RemoteConfigStore
//
//  Evaluates freshness and stale eligibility for cached snapshots.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

public struct TTLPolicy: Sendable, Equatable {
    public let ttl: TimeInterval
    public let maxStaleAge: TimeInterval?

    public init(ttl: TimeInterval, maxStaleAge: TimeInterval? = nil) {
        self.ttl = ttl
        self.maxStaleAge = maxStaleAge
    }

    public func expirationDate(from fetchedAt: Date) -> Date {
        fetchedAt.addingTimeInterval(ttl)
    }

    public func isFresh(_ entry: CacheEntry<RemoteConfigSnapshot>, now: Date = Date()) -> Bool {
        now <= entry.expirationDate
    }

    public func isWithinMaxStaleAge(_ entry: CacheEntry<RemoteConfigSnapshot>, now: Date = Date()) -> Bool {
        guard now > entry.expirationDate else { return true }
        guard let maxStaleAge else { return true }
        return now.timeIntervalSince(entry.expirationDate) <= maxStaleAge
    }

    public func isUsable(_ entry: CacheEntry<RemoteConfigSnapshot>, now: Date = Date()) -> Bool {
        isFresh(entry, now: now) || isWithinMaxStaleAge(entry, now: now)
    }
}
