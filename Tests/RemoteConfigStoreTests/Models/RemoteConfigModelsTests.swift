//
//  RemoteConfigModelsTests.swift
//  RemoteConfigStoreTests
//
//  Verifies key, value, snapshot, and policy model behavior.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation
import Testing
@testable import RemoteConfigStore

struct RemoteConfigModelsTests {
    @Test
    func remoteConfigValueRoundTripsPrimitiveTypes() {
        #expect(RemoteConfigValue.bool(true).boolValue == true)
        #expect(RemoteConfigValue.int(7).intValue == 7)
        #expect(RemoteConfigValue.double(1.5).doubleValue == 1.5)
        #expect(RemoteConfigValue.string("hello").stringValue == "hello")
    }

    @Test
    func typedKeyStoresNameAndDefaultValue() {
        let key = RemoteConfigKey<Bool>("new_ui", defaultValue: false)

        #expect(key.name == "new_ui")
        #expect(key.defaultValue == false)
    }

    @Test
    func snapshotReturnsStoredPrimitiveValues() {
        let snapshot = RemoteConfigSnapshot(
            values: [
                "new_ui": .bool(true),
                "welcome": .string("hello"),
            ],
            fetchedAt: Date(timeIntervalSince1970: 100)
        )

        #expect(snapshot.value(for: "new_ui")?.boolValue == true)
        #expect(snapshot.value(for: "welcome")?.stringValue == "hello")
    }

    @Test
    func readPolicyExposesThreeSupportedModes() {
        #expect(ReadPolicy.immediate == .immediate)
        #expect(ReadPolicy.waitForRefresh == .waitForRefresh)
        #expect(ReadPolicy.immediateWithBackgroundRefresh == .immediateWithBackgroundRefresh)
    }
}
