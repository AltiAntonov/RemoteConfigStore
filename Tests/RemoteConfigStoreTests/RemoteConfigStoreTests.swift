import XCTest
@testable import RemoteConfigStore

final class RemoteConfigStoreTests: XCTestCase {
    func testPackageBuilds() {
        XCTAssertTrue(true)
    }

    func testRemoteConfigValueRoundTripsPrimitiveTypes() {
        XCTAssertEqual(RemoteConfigValue.bool(true).boolValue, true)
        XCTAssertEqual(RemoteConfigValue.int(7).intValue, 7)
        XCTAssertEqual(RemoteConfigValue.double(1.5).doubleValue, 1.5)
        XCTAssertEqual(RemoteConfigValue.string("hello").stringValue, "hello")
    }

    func testTypedKeyStoresNameAndDefaultValue() {
        let key = RemoteConfigKey<Bool>("new_ui", defaultValue: false)

        XCTAssertEqual(key.name, "new_ui")
        XCTAssertEqual(key.defaultValue, false)
    }

    func testSnapshotReturnsStoredPrimitiveValues() {
        let snapshot = RemoteConfigSnapshot(
            values: [
                "new_ui": .bool(true),
                "welcome": .string("hello")
            ],
            fetchedAt: Date(timeIntervalSince1970: 100)
        )

        XCTAssertEqual(snapshot.value(for: "new_ui")?.boolValue, true)
        XCTAssertEqual(snapshot.value(for: "welcome")?.stringValue, "hello")
    }

    func testTTLPolicySeparatesFreshStaleAndExpiredBeyondMaxStale() {
        let now = Date(timeIntervalSince1970: 200)
        let freshEntry = CacheEntry(
            value: RemoteConfigSnapshot(values: [:], fetchedAt: Date(timeIntervalSince1970: 150)),
            expirationDate: Date(timeIntervalSince1970: 250)
        )
        let staleEntry = CacheEntry(
            value: RemoteConfigSnapshot(values: [:], fetchedAt: Date(timeIntervalSince1970: 100)),
            expirationDate: Date(timeIntervalSince1970: 150)
        )
        let policy = TTLPolicy(ttl: 60, maxStaleAge: 120)
        let expiredEntry = CacheEntry(
            value: RemoteConfigSnapshot(values: [:], fetchedAt: Date(timeIntervalSince1970: 0)),
            expirationDate: Date(timeIntervalSince1970: 10)
        )

        XCTAssertTrue(policy.isFresh(freshEntry, now: now))
        XCTAssertTrue(policy.isWithinMaxStaleAge(staleEntry, now: now))
        XCTAssertFalse(policy.isUsable(expiredEntry, now: now))
    }

    func testMemoryCacheStoresAndReturnsEntry() async {
        let cache = MemoryCache<String, RemoteConfigSnapshot>()
        let entry = CacheEntry(
            value: RemoteConfigSnapshot(values: ["new_ui": .bool(true)]),
            expirationDate: Date().addingTimeInterval(60)
        )

        await cache.set(entry, for: "default")
        let loaded = await cache.entry(for: "default")

        XCTAssertEqual(loaded, entry)
    }

    func testDiskCachePersistsEntryToDisk() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let cache = try DiskCache(directory: directory)
        let entry = CacheEntry(
            value: RemoteConfigSnapshot(values: ["new_ui": .bool(true)]),
            expirationDate: Date(timeIntervalSince1970: 500)
        )

        try cache.save(entry, for: "default")
        let loaded = try cache.load(for: "default")

        XCTAssertEqual(loaded, entry)
    }

    func testReadPolicyExposesThreeSupportedModes() {
        XCTAssertEqual(ReadPolicy.immediate, .immediate)
        XCTAssertEqual(ReadPolicy.waitForRefresh, .waitForRefresh)
        XCTAssertEqual(ReadPolicy.immediateWithBackgroundRefresh, .immediateWithBackgroundRefresh)
    }

    func testLoadReturnsFreshMemorySnapshotBeforeHittingNetwork() async throws {
        let fetcher = TestFetcher(result: .success(RemoteConfigSnapshot(values: ["new_ui": .bool(false)])))
        let store = try makeStore(fetcher: fetcher)
        let cached = RemoteConfigSnapshot(values: ["new_ui": .bool(true)], fetchedAt: Date())

        try await store.seed(snapshot: cached)

        let loaded = try await store.load(policy: ReadPolicy.immediate)
        let fetchCount = await fetcher.fetchCount

        XCTAssertEqual(loaded, cached)
        XCTAssertEqual(fetchCount, 0)
    }

    func testLoadReturnsStaleSnapshotWhenWithinMaxStaleAndRefreshFails() async throws {
        let fetcher = TestFetcher(result: .failure(TestError.fetchFailed))
        let store = try makeStore(fetcher: fetcher, ttl: 1, maxStaleAge: 60)
        let stale = RemoteConfigSnapshot(values: ["new_ui": .bool(true)], fetchedAt: Date().addingTimeInterval(-10))

        try await store.seed(snapshot: stale, fetchedAt: Date().addingTimeInterval(-10))

        let loaded = try await store.load(policy: ReadPolicy.waitForRefresh)

        XCTAssertEqual(loaded.values["new_ui"], RemoteConfigValue.bool(true))
    }

    func testValueReturnsTypedDefaultWhenKeyMissing() async throws {
        let fetcher = TestFetcher(result: .success(RemoteConfigSnapshot(values: [:])))
        let store = try makeStore(fetcher: fetcher)
        let key = RemoteConfigKey<Bool>("new_ui", defaultValue: false)

        let value = try await store.value(for: key, policy: ReadPolicy.waitForRefresh)

        XCTAssertEqual(value, false)
    }
}

actor TestFetcher: RemoteConfigFetcher {
    private(set) var fetchCount = 0
    private let result: Result<RemoteConfigSnapshot, Error>

    init(result: Result<RemoteConfigSnapshot, Error>) {
        self.result = result
    }

    func fetch() async throws -> RemoteConfigSnapshot {
        fetchCount += 1
        return try result.get()
    }
}

enum TestError: Error {
    case fetchFailed
}

func makeStore(
    fetcher: some RemoteConfigFetcher,
    ttl: TimeInterval = 60,
    maxStaleAge: TimeInterval? = nil
) throws -> RemoteConfigStore {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    return try RemoteConfigStore(
        fetcher: fetcher,
        cacheDirectory: directory,
        ttl: ttl,
        maxStaleAge: maxStaleAge
    )
}
