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

## Use the built-in HTTP path

When your config comes from a JSON endpoint, you can let the package build the HTTP fetcher for you.

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

If the server returns `ETag` or `Last-Modified`, the store persists that metadata and reuses it during later refreshes.

## Observe refresh updates

Use ``RemoteConfigStore/RemoteConfigStore/updates()`` when you want to react to successful refresh updates.

```swift
let updates = await store.updates()

Task {
    for await update in updates {
        print("Refresh result:", update.result)
    }
}
```

Use ``RemoteConfigStore/RemoteConfigStore/inspectionState()`` when development tools or debug UI need current cache state without triggering a network refresh.

```swift
let state = try await store.inspectionState()
print(state.freshness as Any)
```

## Inspect a cached snapshot

Use ``RemoteConfigStore/RemoteConfigStore/cachedSnapshot()`` when you need the currently cached payload without triggering a refresh path.

```swift
let snapshot = try await store.cachedSnapshot()
let enabled = snapshot.bool(for: AppConfigKeys.newUI)
```

## Next steps

- Learn how each read mode behaves in <doc:ReadPolicies>.
- Learn how refresh observation works in <doc:Observability>.
- Use the example app in `Example/RemoteConfigStore` to see policy differences interactively.
