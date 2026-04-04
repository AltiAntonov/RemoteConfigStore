# Getting Started

Build a store by combining a fetcher, a cache directory, and your freshness settings.

## Define typed keys

```swift
import RemoteConfigStore

enum AppConfigKeys {
    static let newUI = RemoteConfigKey<Bool>("feature.new_ui", defaultValue: false)
    static let welcomeMessage = RemoteConfigKey<String>("welcome_message", defaultValue: "Hello")
}
```

## Implement a fetcher

```swift
import RemoteConfigStore

struct AppFetcher: RemoteConfigFetcher {
    func fetchSnapshot() async throws -> RemoteConfigSnapshot {
        RemoteConfigSnapshot(values: [
            "feature.new_ui": .bool(true),
            "welcome_message": .string("Fresh config is active.")
        ])
    }
}
```

## Create the store

```swift
import Foundation
import RemoteConfigStore

let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]

let store = try RemoteConfigStore(
    fetcher: AppFetcher(),
    cacheDirectory: directory.appendingPathComponent("RemoteConfigStore"),
    ttl: 300,
    maxStaleAge: 3600
)
```

## Read configuration values

```swift
let enabled = try await store.bool(for: AppConfigKeys.newUI, using: .immediate)
let message = try await store.string(for: AppConfigKeys.welcomeMessage, using: .refreshBeforeReturning)
```

## Inspect a cached snapshot

Use ``RemoteConfigStore/RemoteConfigStore/cachedSnapshot()`` when you need the currently cached payload without triggering a refresh path.

```swift
let snapshot = try await store.cachedSnapshot()
let enabled = snapshot.bool(for: AppConfigKeys.newUI)
```

## Next steps

- Learn how each read mode behaves in <doc:ReadPolicies>.
- Use the example app in `Example/RemoteConfigStore` to see policy differences interactively.
