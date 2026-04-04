import Foundation

public actor RemoteConfigStore {
    private let fetcher: any RemoteConfigFetcher
    private let memoryCache = MemoryCache<String, RemoteConfigSnapshot>()
    private let diskCache: DiskCache
    private let ttlPolicy: TTLPolicy
    private let logger: any Logger
    private let cacheKey = "default"

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

    public func snapshot() async throws -> RemoteConfigSnapshot {
        if let entry = await memoryCache.entry(for: cacheKey) {
            return entry.value
        }

        if let entry = try diskCache.load(for: cacheKey) {
            await memoryCache.set(entry, for: cacheKey)
            return entry.value
        }

        throw RemoteConfigStoreError.noCachedSnapshot
    }

    public func refresh() async throws -> RemoteConfigSnapshot {
        logger.log("Fetching remote config")
        let snapshot = try await fetcher.fetch()
        let entry = CacheEntry(
            value: snapshot,
            expirationDate: ttlPolicy.expirationDate(from: snapshot.fetchedAt)
        )

        await memoryCache.set(entry, for: cacheKey)
        try diskCache.save(entry, for: cacheKey)
        return snapshot
    }

    public func load(policy: ReadPolicy) async throws -> RemoteConfigSnapshot {
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
            case .waitForRefresh:
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
                    Task {
                        try? await self.refresh()
                    }
                    return entry.value
                }
                return try await refresh()
            }
        }

        return try await refresh()
    }

    public func value(for key: RemoteConfigKey<Bool>, policy: ReadPolicy = .immediate) async throws -> Bool {
        let snapshot = try await load(policy: policy)
        return snapshot.value(for: key.name)?.boolValue ?? key.defaultValue
    }

    public func value(for key: RemoteConfigKey<Int>, policy: ReadPolicy = .immediate) async throws -> Int {
        let snapshot = try await load(policy: policy)
        return snapshot.value(for: key.name)?.intValue ?? key.defaultValue
    }

    public func value(for key: RemoteConfigKey<Double>, policy: ReadPolicy = .immediate) async throws -> Double {
        let snapshot = try await load(policy: policy)
        return snapshot.value(for: key.name)?.doubleValue ?? key.defaultValue
    }

    public func value(for key: RemoteConfigKey<String>, policy: ReadPolicy = .immediate) async throws -> String {
        let snapshot = try await load(policy: policy)
        return snapshot.value(for: key.name)?.stringValue ?? key.defaultValue
    }

    public func seed(snapshot: RemoteConfigSnapshot, fetchedAt: Date? = nil) async throws {
        let effectiveFetchedAt = fetchedAt ?? snapshot.fetchedAt
        let entry = CacheEntry(
            value: RemoteConfigSnapshot(values: snapshot.values, fetchedAt: effectiveFetchedAt),
            expirationDate: ttlPolicy.expirationDate(from: effectiveFetchedAt)
        )

        await memoryCache.set(entry, for: cacheKey)
        try diskCache.save(entry, for: cacheKey)
    }
}
