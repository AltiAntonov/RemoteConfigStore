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
}
