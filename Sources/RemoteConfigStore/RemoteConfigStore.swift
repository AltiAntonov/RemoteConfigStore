//
//  RemoteConfigStore.swift
//  RemoteConfigStore
//
//  Coordinates cache lookup, refresh, and typed value access.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Coordinates cache lookup, refresh work, and typed value access for remote configuration.
public actor RemoteConfigStore {
    private let fetcher: any RemoteConfigFetcher
    private let memoryCache = MemoryCache<String, RemoteConfigSnapshot>()
    private let diskCache: DiskCache
    private let ttlPolicy: TTLPolicy
    private let logger: any Logger
    private let cacheKey = "default"
    private var refreshTask: Task<RemoteConfigRefreshResult, Error>?

    /// Creates a remote configuration store.
    ///
    /// - Parameters:
    ///   - fetcher: The component responsible for loading fresh snapshots.
    ///   - cacheDirectory: The directory used to persist cached snapshots.
    ///   - ttl: The duration a fetched snapshot remains fresh.
    ///   - maxStaleAge: The optional extra window in which stale data remains usable.
    ///   - logger: The logger used for cache and refresh events.
    /// - Throws: An error if the cache directory cannot be prepared.
    public init(
        fetcher: any RemoteConfigFetcher,
        cacheDirectory: URL,
        ttl: TimeInterval,
        maxStaleAge: TimeInterval? = nil,
        logger: any Logger = NoopLogger()
    ) throws {
        self.fetcher = fetcher
        self.diskCache = try DiskCache(directory: cacheDirectory)
        self.ttlPolicy = TTLPolicy(ttl: ttl, maxStaleAge: maxStaleAge)
        self.logger = logger
    }

    /// Creates a remote configuration store backed by the built-in HTTP fetcher.
    ///
    /// - Parameters:
    ///   - request: The HTTP request configuration for the remote config endpoint.
    ///   - cacheDirectory: The directory used to persist cached snapshots.
    ///   - ttl: The duration a fetched snapshot remains fresh.
    ///   - maxStaleAge: The optional extra window in which stale data remains usable.
    ///   - session: The session used to perform HTTP requests.
    ///   - logger: The logger used for cache and refresh events.
    /// - Throws: An error if the cache directory cannot be prepared.
    public init(
        request: HTTPRemoteConfigRequest,
        cacheDirectory: URL,
        ttl: TimeInterval,
        maxStaleAge: TimeInterval? = nil,
        session: URLSession = .shared,
        logger: any Logger = NoopLogger()
    ) throws {
        try self.init(
            fetcher: HTTPRemoteConfigFetcher(request: request, session: session),
            cacheDirectory: cacheDirectory,
            ttl: ttl,
            maxStaleAge: maxStaleAge,
            logger: logger
        )
    }

    /// Returns the currently cached snapshot.
    ///
    /// - Returns: The cached snapshot loaded from memory or disk.
    /// - Throws: `RemoteConfigStoreError.noCachedSnapshot` when nothing is cached.
    public func cachedSnapshot() async throws -> RemoteConfigSnapshot {
        if let entry = await memoryCache.entry(for: cacheKey) {
            return entry.value
        }

        if let entry = try diskCache.load(for: cacheKey) {
            await memoryCache.set(entry, for: cacheKey)
            return entry.value
        }

        throw RemoteConfigStoreError.noCachedSnapshot
    }

    /// Forces a refresh and updates both memory and disk caches.
    ///
    /// Concurrent callers share a single in-flight refresh task.
    ///
    /// - Returns: The freshly fetched snapshot.
    /// - Throws: An error describing why the refresh failed.
    public func refresh() async throws -> RemoteConfigSnapshot {
        return try await refreshResult().snapshot
    }

    /// Forces a refresh and reports whether the fetched payload changed.
    ///
    /// Concurrent callers share a single in-flight refresh task.
    ///
    /// - Returns: A result describing whether the payload changed and the refreshed snapshot.
    /// - Throws: An error describing why the refresh failed.
    public func refreshResult() async throws -> RemoteConfigRefreshResult {
        if let refreshTask {
            return try await refreshTask.value
        }

        logger.log("Fetching remote config")
        let memoryEntry = await memoryCache.entry(for: cacheKey)
        let diskEntry = try diskCache.load(for: cacheKey)
        let cachedEntry = memoryEntry ?? diskEntry
        let task = Task {
            try await refreshResult(cachedEntry: cachedEntry)
        }
        refreshTask = task

        do {
            let result = try await task.value
            let entry = CacheEntry(
                value: result.snapshot,
                expirationDate: ttlPolicy.expirationDate(from: result.snapshot.fetchedAt)
            )

            await memoryCache.set(entry, for: cacheKey)
            try diskCache.save(entry, for: cacheKey)
            refreshTask = nil
            return result
        } catch {
            refreshTask = nil
            throw error
        }
    }

    /// Returns a snapshot using the supplied read policy.
    ///
    /// - Parameter policy: The strategy used to balance cached reads against refresh work.
    /// - Returns: A snapshot selected according to the supplied policy.
    /// - Throws: An error when no usable cached snapshot exists and refresh fails.
    public func snapshot(using policy: ReadPolicy) async throws -> RemoteConfigSnapshot {
        let now = Date()
        let memoryEntry = await memoryCache.entry(for: cacheKey)
        let diskEntry = try diskCache.load(for: cacheKey)

        if let entry = memoryEntry ?? diskEntry {
            await memoryCache.set(entry, for: cacheKey)

            if ttlPolicy.isFresh(entry, now: now) {
                logger.log("Cache hit")
                return entry.value
            }

            switch policy {
            case .immediate:
                if ttlPolicy.isUsable(entry, now: now) {
                    return entry.value
                }
                return try await refresh()
            case .refreshBeforeReturning:
                do {
                    return try await refresh()
                } catch {
                    if ttlPolicy.isUsable(entry, now: now) {
                        logger.log("Returning stale config after refresh failure")
                        return entry.value
                    }
                    throw error
                }
            case .immediateWithBackgroundRefresh:
                if ttlPolicy.isUsable(entry, now: now) {
                    if refreshTask == nil {
                        Task {
                            try? await self.refresh()
                        }
                    }
                    return entry.value
                }
                return try await refresh()
            }
        }

        return try await refresh()
    }

    /// Returns a Boolean value for the supplied key.
    ///
    /// This convenience overload keeps call sites explicit about the requested primitive type.
    ///
    /// - Parameters:
    ///   - key: The typed key to resolve.
    ///   - policy: The strategy used to load the backing snapshot.
    /// - Returns: The stored value or the key's default value.
    /// - Throws: An error when no usable snapshot can be loaded.
    public func bool(for key: RemoteConfigKey<Bool>, using policy: ReadPolicy = .immediate) async throws -> Bool {
        try await value(for: key, using: policy)
    }

    /// Returns a Boolean value for the supplied key.
    ///
    /// - Parameters:
    ///   - key: The typed key to resolve.
    ///   - policy: The strategy used to load the backing snapshot.
    /// - Returns: The stored value or the key's default value.
    /// - Throws: An error when no usable snapshot can be loaded.
    public func value(for key: RemoteConfigKey<Bool>, using policy: ReadPolicy = .immediate) async throws -> Bool {
        let snapshot = try await snapshot(using: policy)
        return snapshot.value(for: key.name)?.boolValue ?? key.defaultValue
    }

    /// Returns an integer value for the supplied key.
    ///
    /// This convenience overload keeps call sites explicit about the requested primitive type.
    ///
    /// - Parameters:
    ///   - key: The typed key to resolve.
    ///   - policy: The strategy used to load the backing snapshot.
    /// - Returns: The stored value or the key's default value.
    /// - Throws: An error when no usable snapshot can be loaded.
    public func int(for key: RemoteConfigKey<Int>, using policy: ReadPolicy = .immediate) async throws -> Int {
        try await value(for: key, using: policy)
    }

    /// Returns an integer value for the supplied key.
    ///
    /// - Parameters:
    ///   - key: The typed key to resolve.
    ///   - policy: The strategy used to load the backing snapshot.
    /// - Returns: The stored value or the key's default value.
    /// - Throws: An error when no usable snapshot can be loaded.
    public func value(for key: RemoteConfigKey<Int>, using policy: ReadPolicy = .immediate) async throws -> Int {
        let snapshot = try await snapshot(using: policy)
        return snapshot.value(for: key.name)?.intValue ?? key.defaultValue
    }

    /// Returns a floating-point value for the supplied key.
    ///
    /// This convenience overload keeps call sites explicit about the requested primitive type.
    ///
    /// - Parameters:
    ///   - key: The typed key to resolve.
    ///   - policy: The strategy used to load the backing snapshot.
    /// - Returns: The stored value or the key's default value.
    /// - Throws: An error when no usable snapshot can be loaded.
    public func double(for key: RemoteConfigKey<Double>, using policy: ReadPolicy = .immediate) async throws -> Double {
        try await value(for: key, using: policy)
    }

    /// Returns a floating-point value for the supplied key.
    ///
    /// - Parameters:
    ///   - key: The typed key to resolve.
    ///   - policy: The strategy used to load the backing snapshot.
    /// - Returns: The stored value or the key's default value.
    /// - Throws: An error when no usable snapshot can be loaded.
    public func value(for key: RemoteConfigKey<Double>, using policy: ReadPolicy = .immediate) async throws -> Double {
        let snapshot = try await snapshot(using: policy)
        return snapshot.value(for: key.name)?.doubleValue ?? key.defaultValue
    }

    /// Returns a string value for the supplied key.
    ///
    /// This convenience overload keeps call sites explicit about the requested primitive type.
    ///
    /// - Parameters:
    ///   - key: The typed key to resolve.
    ///   - policy: The strategy used to load the backing snapshot.
    /// - Returns: The stored value or the key's default value.
    /// - Throws: An error when no usable snapshot can be loaded.
    public func string(for key: RemoteConfigKey<String>, using policy: ReadPolicy = .immediate) async throws -> String {
        try await value(for: key, using: policy)
    }

    /// Returns a string value for the supplied key.
    ///
    /// - Parameters:
    ///   - key: The typed key to resolve.
    ///   - policy: The strategy used to load the backing snapshot.
    /// - Returns: The stored value or the key's default value.
    /// - Throws: An error when no usable snapshot can be loaded.
    public func value(for key: RemoteConfigKey<String>, using policy: ReadPolicy = .immediate) async throws -> String {
        let snapshot = try await snapshot(using: policy)
        return snapshot.value(for: key.name)?.stringValue ?? key.defaultValue
    }

    func seedSnapshot(_ snapshot: RemoteConfigSnapshot, fetchedAt: Date? = nil) async throws {
        let effectiveFetchedAt = fetchedAt ?? snapshot.fetchedAt
        let entry = CacheEntry(
            value: RemoteConfigSnapshot(
                values: snapshot.values,
                fetchedAt: effectiveFetchedAt,
                httpValidationMetadata: snapshot.httpValidationMetadata
            ),
            expirationDate: ttlPolicy.expirationDate(from: effectiveFetchedAt)
        )

        await memoryCache.set(entry, for: cacheKey)
        try diskCache.save(entry, for: cacheKey)
    }

    private func refreshResult(
        cachedEntry: CacheEntry<RemoteConfigSnapshot>?
    ) async throws -> RemoteConfigRefreshResult {
        do {
            let snapshot = try await fetchSnapshot(
                validationMetadata: cachedEntry?.value.httpValidationMetadata
            )

            if let cachedEntry, cachedEntry.value.hasSamePayload(as: snapshot) {
                logger.log("Remote config unchanged")
                return .unchanged(snapshot)
            }

            return .updated(snapshot)
        } catch let HTTPRemoteConfigFetcherError.notModified(metadata) {
            guard let cachedEntry else {
                throw HTTPRemoteConfigFetcherError.notModified(metadata)
            }

            logger.log("Remote config not modified")
            return .unchanged(
                RemoteConfigSnapshot(
                    values: cachedEntry.value.values,
                    fetchedAt: Date(),
                    httpValidationMetadata: metadata ?? cachedEntry.value.httpValidationMetadata
                )
            )
        }
    }

    private func fetchSnapshot(
        validationMetadata: HTTPRemoteConfigValidationMetadata?
    ) async throws -> RemoteConfigSnapshot {
        if let fetcher = fetcher as? HTTPRemoteConfigFetcher {
            return try await fetcher.fetchSnapshot(validationMetadata: validationMetadata)
        }

        return try await fetcher.fetchSnapshot()
    }
}
