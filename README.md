<div align="center">
  <h1>RemoteConfigStore</h1>
  <p><strong>Offline-first remote config caching with TTL, stale fallback, and typed keys.</strong></p>
  <p>
    <img src="https://img.shields.io/badge/Swift-6.0%2B-F05138" alt="Swift 6.0+">
    <img src="https://img.shields.io/badge/Platforms-iOS%2017%2B%20%7C%20macOS%2014%2B-0A84FF" alt="Platforms">
    <img src="https://img.shields.io/badge/License-MIT-34C759" alt="MIT License">
  </p>
  <p>
    <a href="#features">Features</a> ·
    <a href="#installation">Installation</a> ·
    <a href="#quick-start">Quick Start</a> ·
    <a href="#read-policies">Read Policies</a> ·
    <a href="#freshness-model">Freshness Model</a> ·
    <a href="#example-app">Example App</a> ·
    <a href="#testing">Testing</a> ·
    <a href="#roadmap">Roadmap</a>
  </p>
</div>

## Features

- memory and disk-backed cache layers
- TTL-based freshness
- optional stale fallback using `maxStaleAge`
- injected fetcher protocol for remote loading
- typed key access for primitive values
- actor-backed store implementation for serialized state access

## Installation

Add `RemoteConfigStore` to your Swift Package Manager dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/AltiAntonov/RemoteConfigStore.git", from: "0.1.0")
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

Until the first tagged release exists, use the local package directly in Xcode or pin to a branch or revision as needed.

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

## Read Policies

`RemoteConfigStore` currently supports three read policies:

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

## Example App

The repository contains an Xcode example app scaffold in `Example/RemoteConfigStore`.

Current status:

- local package linkage is configured
- the app is intentionally lightweight for now
- the richer showcase behavior will be built incrementally later

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

## Roadmap

### `v0.1`

- typed primitive values
- memory and disk cache
- TTL and optional stale fallback
- injected fetcher protocol
- policy-based reads

### Later

- built-in HTTP client
- ETag support
- version diffing
- observers / change streams
- metrics and analytics hooks
- nested consumer-defined model decoding
