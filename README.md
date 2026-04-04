# RemoteConfigStore

Offline-first remote config caching for iOS and Apple-platform apps.

## Features

- memory and disk-backed cache
- TTL-based freshness
- optional stale fallback with `maxStaleAge`
- injected fetcher protocol
- typed key access for primitive values

## Installation

Add the package to your Swift Package Manager dependencies.

## Usage

```swift
import Foundation
import RemoteConfigStore

enum AppConfigKeys {
    static let newUI = RemoteConfigKey<Bool>("new_ui", defaultValue: false)
}

struct AppFetcher: RemoteConfigFetcher {
    func fetch() async throws -> RemoteConfigSnapshot {
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

let enabled = try await store.value(for: AppConfigKeys.newUI, policy: .immediate)
```

## Freshness Model

- fresh values return from cache immediately
- stale values may still be served if they are within `maxStaleAge`
- `waitForRefresh` attempts a refresh before returning
- `immediateWithBackgroundRefresh` returns usable cached data and refreshes in the background

## Status

`v0.1` supports primitive values only. Built-in HTTP fetching, ETag handling, and nested model decoding are planned for later versions.
