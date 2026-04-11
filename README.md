<div align="center">
  <h1>RemoteConfigStore</h1>
  <p><strong>Offline-first remote config caching with TTL, stale fallback, and typed keys.</strong></p>
  <p>
    <a href="https://swiftpackageindex.com/AltiAntonov/RemoteConfigStore">
      <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAltiAntonov%2FRemoteConfigStore%2Fbadge%3Ftype%3Dswift-versions" alt="Swift version compatibility">
    </a>
    <a href="https://swiftpackageindex.com/AltiAntonov/RemoteConfigStore">
      <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FAltiAntonov%2FRemoteConfigStore%2Fbadge%3Ftype%3Dplatforms" alt="Platform compatibility">
    </a>
    <img src="https://img.shields.io/badge/License-MIT-34C759" alt="MIT License">
    <a href="https://github.com/AltiAntonov/RemoteConfigStore/actions/workflows/swift.yml"><img src="https://github.com/AltiAntonov/RemoteConfigStore/actions/workflows/swift.yml/badge.svg" alt="Swift workflow"></a>
  </p>
  <p>
    <a href="#features">Features</a> ·
    <a href="#installation">Installation</a> ·
    <a href="#quick-start">Quick Start</a> ·
    <a href="#when-to-use-remoteconfigstore">When To Use</a> ·
    <a href="#good-fits">Good Fits</a> ·
    <a href="#weaker-fits">Weaker Fits</a> ·
    <a href="#read-policies">Read Policies</a> ·
    <a href="#freshness-model">Freshness Model</a> ·
    <a href="#errors">Errors</a> ·
    <a href="#example-app">Example App</a> ·
    <a href="#documentation">Documentation</a> ·
    <a href="#testing">Testing</a> ·
    <a href="#example-scenarios">Example Scenarios</a>
  </p>
</div>

## Features

- memory and disk-backed cache layers
- TTL-based freshness
- optional stale fallback using `maxStaleAge`
- injected fetcher protocol for remote loading
- typed key access for primitive values
- actor-backed store implementation for serialized state access

The public API is intentionally centered on:

- `RemoteConfigStore`
- `RemoteConfigFetcher`
- `RemoteConfigSnapshot`
- `RemoteConfigRefreshResult`
- `RemoteConfigKey`
- `RemoteConfigValue`
- `ReadPolicy`
- `RemoteConfigStoreError`
- `Logger`

## Installation

Add `RemoteConfigStore` to your Swift Package Manager dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/AltiAntonov/RemoteConfigStore.git", from: "0.3.1")
]
```

Then add the product to your target:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "RemoteConfigStore", package: "RemoteConfigStore")
    ]
)
```

If you need to try unreleased changes, pin to a branch or revision explicitly.

## Quick Start

```swift
import Foundation
import RemoteConfigStore

enum AppConfigKeys {
    static let newUI = RemoteConfigKey<Bool>("new_ui", defaultValue: false)
}

struct AppFetcher: RemoteConfigFetcher {
    func fetchSnapshot() async throws -> RemoteConfigSnapshot {
        RemoteConfigSnapshot(values: [
            "new_ui": .bool(true)
        ])
    }
}

let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
let store = try RemoteConfigStore(
    fetcher: AppFetcher(),
    cacheDirectory: directory.appendingPathComponent("RemoteConfigStore"),
    ttl: 300,
    maxStaleAge: 3600
)

let enabled = try await store.value(for: AppConfigKeys.newUI, using: .immediate)
```

If you need to know whether a refresh actually changed the payload, use `refreshResult()`:

```swift
switch try await store.refreshResult() {
case .updated(let snapshot):
    print("Config changed:", snapshot.values)
case .unchanged:
    print("Config payload is unchanged.")
}
```

You can also use the built-in HTTP path when your config comes from a JSON endpoint:

```swift
let store = try RemoteConfigStore(
    request: HTTPRemoteConfigRequest(
        url: URL(string: "https://example.com/remote-config.json")!,
        headers: ["Authorization": "Bearer token"],
        timeoutInterval: 8
    ),
    cacheDirectory: directory.appendingPathComponent("RemoteConfigStore"),
    ttl: 300
)
```

When the built-in HTTP fetcher receives `ETag` or `Last-Modified` headers, the store persists that validation metadata and uses it for later conditional refreshes.

## When To Use RemoteConfigStore

Use `RemoteConfigStore` when an app needs server-driven values but should still behave predictably when the network is slow, unavailable, or temporarily failing.

It is a strong fit for configuration that should be cached locally, refreshed deliberately, and read through a typed API instead of raw dictionaries spread across an app.

## Good Fits

- Feature flags and staged rollout controls
  Example: [Feature Flags scenario](Example/RemoteConfigStore/RemoteConfigStore/Scenarios/FeatureFlags/FeatureFlagsDemoView.swift)
- Runtime tuning values such as request timeouts, polling intervals, and rollout percentages
  Example: [Feature Flags scenario](Example/RemoteConfigStore/RemoteConfigStore/Scenarios/FeatureFlags/FeatureFlagsDemoView.swift)
- Remote text or copy that should remain available offline
  Example: [Feature Flags scenario](Example/RemoteConfigStore/RemoteConfigStore/Scenarios/FeatureFlags/FeatureFlagsDemoView.swift)
- Safety switches and operational config that benefit from stale fallback instead of hard failure
  Example soon
- Apps that care about startup speed and want cache-first or stale-while-revalidate reads
  Example: [Feature Flags scenario](Example/RemoteConfigStore/RemoteConfigStore/Scenarios/FeatureFlags/FeatureFlagsDemoView.swift)

## Weaker Fits

- Deeply nested or highly structured configuration documents
  Example soon
- Cases where config must always be fresh and stale data is never acceptable
  Example soon
- Projects that need a built-in HTTP client, ETag validation, or observer streams today
  Example: [HTTP Cache Validation scenario](Example/RemoteConfigStore/RemoteConfigStore/Scenarios/HTTPFetcher/HTTPFetcherDemoView.swift)
- Data that is really user content or secure secret material rather than app configuration
  Example soon

## Read Policies

`RemoteConfigStore` currently supports three read policies:

| Policy | Fresh cache | Stale but usable cache | No usable cache | Best fit |
| --- | --- | --- | --- | --- |
| `.immediate` | returns cache | returns cache | waits for refresh | fast UI reads |
| `.refreshBeforeReturning` | returns cache | tries refresh first | waits for refresh | freshest possible values |
| `.immediateWithBackgroundRefresh` | returns cache | returns cache and refreshes in background | waits for refresh | responsive reads with silent catch-up |

### `.immediate`

Return a usable cached snapshot immediately when one exists.

- fresh cache: returned immediately
- stale but still usable cache: returned immediately
- no usable cache: refresh is attempted and its result is returned
- refresh failure with no usable cache: throws

Use this when UI responsiveness matters more than eagerly refreshing stale data.

### `.refreshBeforeReturning`

Prefer a refresh before returning stale data.

- fresh cache: returned immediately
- stale cache: refresh is attempted first
- refresh failure with still-usable stale cache: stale data is returned
- refresh failure with no usable cache: throws

Use this when you want the newest possible config before continuing, but still need an offline fallback.

### `.immediateWithBackgroundRefresh`

Return usable cached data now and refresh asynchronously in the background.

- fresh or stale-but-usable cache: returned immediately
- a background refresh is scheduled
- no usable cache: refresh is awaited directly

Use this when you want instant reads while still nudging the cache toward freshness.

## Freshness Model

The store uses two time windows:

- `ttl`: how long a fetched snapshot is considered fresh
- `maxStaleAge`: an optional extra window during which expired data may still be served

That creates three states:

1. `fresh`
   The cache is within `ttl` and can be returned without qualification.

2. `stale but usable`
   The cache is older than `ttl`, but still within `maxStaleAge`.

3. `expired and unusable`
   The cache is older than both windows and must not be used as a fallback.

## Errors

`RemoteConfigStore` keeps its store-specific error surface intentionally small.

- `RemoteConfigStoreError.noCachedSnapshot`: returned when neither memory nor disk cache contains a snapshot

Other failures are propagated from the underlying component that failed:

- `refresh()` and `snapshot(using:)` can throw the injected fetcher's error
- `refresh()` can throw cache persistence or file-system errors from disk writes
- `cachedSnapshot()` can throw file-system errors while loading from disk
- `RemoteConfigStore.init(...)` can throw when the cache directory cannot be prepared

## Example App

The repository includes an Xcode example app in `Example/RemoteConfigStore`.

Current scenarios:

- `Feature Flags`
  Code: [FeatureFlagsDemoView.swift](Example/RemoteConfigStore/RemoteConfigStore/Scenarios/FeatureFlags/FeatureFlagsDemoView.swift)
  Shows typed keys, all three read policies, manual refreshes, revision drift, and the difference between typed accessors and the raw cached payload.
- `HTTP Fetcher`
  Code: [HTTPFetcherDemoView.swift](Example/RemoteConfigStore/RemoteConfigStore/Scenarios/HTTPFetcher/HTTPFetcherDemoView.swift)
  Shows the built-in `URLSession` fetcher, URL-based store construction, typed-key reads, and refresh-result reporting.
- `HTTP Cache Validation`
  Code: [HTTPFetcherDemoView.swift](Example/RemoteConfigStore/RemoteConfigStore/Scenarios/HTTPFetcher/HTTPFetcherDemoView.swift)
  Shows persisted ETag metadata, conditional requests, `304 Not Modified`, and cache freshness renewal without a payload change.

Planned scenarios:

- `Offline Fallback` - Example soon
- `Observers And Metrics` - Example soon

## Documentation

The package now includes a DocC catalog in `Sources/RemoteConfigStore/RemoteConfigStore.docc`.

Once Swift Package Index processes the `.spi.yml` manifest and the DocC catalog, hosted documentation should appear on the package page automatically.

Current DocC coverage includes:

- getting started with injected fetchers
- read policy behavior
- built-in HTTP cache validation behavior

## Example Scenarios

The example app is designed as one showcase application with multiple focused scenarios rather than many separate demo projects.

Implemented:

- `Feature Flags`
  Code: [FeatureFlagsDemoView.swift](Example/RemoteConfigStore/RemoteConfigStore/Scenarios/FeatureFlags/FeatureFlagsDemoView.swift)
- `HTTP Fetcher`
  Code: [HTTPFetcherDemoView.swift](Example/RemoteConfigStore/RemoteConfigStore/Scenarios/HTTPFetcher/HTTPFetcherDemoView.swift)
- `HTTP Cache Validation`
  Code: [HTTPFetcherDemoView.swift](Example/RemoteConfigStore/RemoteConfigStore/Scenarios/HTTPFetcher/HTTPFetcherDemoView.swift)

Coming later:

- `Offline Fallback` - Example soon
- `Structured Payloads` - Example soon

If you create a fresh example app manually in the future, recommended Xcode options are:

- template: `iOS App`
- interface: `SwiftUI`
- language: `Swift`
- testing: `Swift Testing`
- Core Data: `No`
- development team: unset unless signing is needed locally

## Testing

Package tests now use `Swift Testing`, not `XCTest`.

Current structure:

- `Tests/RemoteConfigStoreTests/Models`
- `Tests/RemoteConfigStoreTests/Cache`
- `Tests/RemoteConfigStoreTests/Store`
- `Tests/RemoteConfigStoreTests/Support`

Run the package tests with:

```bash
swift test
```

See [CHANGELOG.md](CHANGELOG.md) for released changes.
