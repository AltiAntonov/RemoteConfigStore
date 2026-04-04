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
    func snapshotConvenienceAccessorsResolveTypedKeys() {
        let snapshot = RemoteConfigSnapshot(
            values: [
                "feature.new_ui": .bool(true),
                "welcome_message": .string("Hello"),
                "request_timeout_ms": .int(5_000),
                "rollout_fraction": .double(0.25),
            ]
        )

        let newUI = snapshot.bool(for: .init("feature.new_ui", defaultValue: false))
        let welcomeMessage = snapshot.string(for: .init("welcome_message", defaultValue: "Fallback"))
        let requestTimeout = snapshot.int(for: .init("request_timeout_ms", defaultValue: 1_000))
        let rolloutFraction = snapshot.double(for: .init("rollout_fraction", defaultValue: 1.0))

        #expect(newUI == true)
        #expect(welcomeMessage == "Hello")
        #expect(requestTimeout == 5_000)
        #expect(rolloutFraction == 0.25)
    }

    @Test
    func snapshotReportsAgeAndFreshness() {
        let now = Date(timeIntervalSince1970: 1_000)
        let snapshot = RemoteConfigSnapshot(
            values: [:],
            fetchedAt: Date(timeIntervalSince1970: 900)
        )

        #expect(snapshot.age(relativeTo: now) == 100)
        #expect(snapshot.freshness(ttl: 120, relativeTo: now) == .fresh)
        #expect(snapshot.freshness(ttl: 60, maxStaleAge: 60, relativeTo: now) == .stale)
        #expect(snapshot.freshness(ttl: 30, maxStaleAge: 30, relativeTo: now) == .expired)
    }

    @Test
    func readPolicyExposesThreeSupportedModes() {
        #expect(ReadPolicy.immediate == .immediate)
        #expect(ReadPolicy.refreshBeforeReturning == .refreshBeforeReturning)
        #expect(ReadPolicy.immediateWithBackgroundRefresh == .immediateWithBackgroundRefresh)
    }
}
