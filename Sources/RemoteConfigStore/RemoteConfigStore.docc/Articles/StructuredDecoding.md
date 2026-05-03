# Structured Decoding

Decode small nested config objects into consumer-defined Swift models.

## Overview

Primitive typed keys are still the clearest fit for feature flags, strings, numbers, and simple rollout values. Structured decoding is intended for one config key that owns a compact object, such as paywall copy, onboarding copy, or grouped operational settings.

```swift
struct PaywallConfig: Decodable, Sendable {
    let title: String
    let enabled: Bool
    let tiers: [String]
}

let paywall = try await store.decodedValue(
    PaywallConfig.self,
    for: "paywall",
    using: .immediate
)
```

## Snapshot Decoding

Use ``RemoteConfigSnapshot/decodedValue(_:for:)`` when you already have a snapshot and want to decode from it without triggering cache or refresh work.

```swift
let snapshot = try await store.cachedSnapshot()
let paywall = try snapshot.decodedValue(PaywallConfig.self, for: "paywall")
```

## Error Behavior

Structured decoding throws ``RemoteConfigDecodingError`` when the key is missing or the stored value cannot be decoded into the requested model.

This keeps malformed remote configuration visible instead of silently substituting a partial object.

## Supported Raw Shapes

``RemoteConfigValue`` supports booleans, integers, doubles, strings, objects, arrays, and nulls.

The built-in HTTP fetcher decodes those shapes from JSON payloads before the store caches the snapshot.
