//
//  TTLPolicy.swift
//  RemoteConfigStore
//
//  Evaluates freshness and stale eligibility for cached snapshots.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Evaluates freshness and stale eligibility for cached snapshots.
public struct TTLPolicy: Sendable, Equatable {
    /// The duration a fetched snapshot remains fresh.
    public let ttl: TimeInterval
    /// The optional extra time an expired snapshot may still be served.
    public let maxStaleAge: TimeInterval?

    /// Creates a freshness policy.
    ///
    /// - Parameters:
    ///   - ttl: The duration a fetched snapshot remains fresh.
    ///   - maxStaleAge: The optional extra window in which stale data remains usable.
    public init(ttl: TimeInterval, maxStaleAge: TimeInterval? = nil) {
        self.ttl = ttl
        self.maxStaleAge = maxStaleAge
    }

    /// Returns the expiration date for a given fetch time.
    ///
    /// - Parameter fetchedAt: The time when the snapshot was fetched.
    /// - Returns: The freshness cutoff for that snapshot.
    public func expirationDate(from fetchedAt: Date) -> Date {
        fetchedAt.addingTimeInterval(ttl)
    }

    /// Returns whether an entry is still fresh.
    ///
    /// - Parameters:
    ///   - entry: The cache entry to inspect.
    ///   - now: The reference time used for the check.
    /// - Returns: `true` when the entry is still within its TTL.
    public func isFresh(_ entry: CacheEntry<RemoteConfigSnapshot>, now: Date = Date()) -> Bool {
        now <= entry.expirationDate
    }

    /// Returns whether an expired entry is still inside its stale fallback window.
    ///
    /// - Parameters:
    ///   - entry: The cache entry to inspect.
    ///   - now: The reference time used for the check.
    /// - Returns: `true` when the entry may still be served as stale data.
    public func isWithinMaxStaleAge(_ entry: CacheEntry<RemoteConfigSnapshot>, now: Date = Date()) -> Bool {
        guard now > entry.expirationDate else { return true }
        guard let maxStaleAge else { return true }
        return now.timeIntervalSince(entry.expirationDate) <= maxStaleAge
    }

    /// Returns whether an entry may be used for reads.
    ///
    /// - Parameters:
    ///   - entry: The cache entry to inspect.
    ///   - now: The reference time used for the check.
    /// - Returns: `true` when the entry is fresh or still inside its stale fallback window.
    public func isUsable(_ entry: CacheEntry<RemoteConfigSnapshot>, now: Date = Date()) -> Bool {
        isFresh(entry, now: now) || isWithinMaxStaleAge(entry, now: now)
    }
}
