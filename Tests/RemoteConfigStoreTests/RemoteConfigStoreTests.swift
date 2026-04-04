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
}
