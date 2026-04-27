# Observability

React to refresh updates and inspect store state without coupling app code to cache internals.

## Update stream

Call ``RemoteConfigStore/RemoteConfigStore/updates()`` to create an independent async stream of successful refresh updates.

```swift
let updates = await store.updates()

Task {
    for await update in updates {
        switch update.result {
        case .updated(let snapshot):
            print("Config updated:", snapshot.values)
        case .unchanged:
            print("Config revalidated without a payload change.")
        }
    }
}
```

The stream emits after the store writes the refreshed snapshot to memory and disk.

## Update hook

Use the `onUpdate` initializer parameter when a lightweight callback is more convenient than consuming an async stream.

```swift
let store = try RemoteConfigStore(
    fetcher: AppFetcher(),
    cacheDirectory: cacheDirectory,
    ttl: 300,
    onUpdate: { update in
        print("Refresh event:", update.result)
    }
)
```

Keep this hook small. It is intended for visibility and simple integrations, not analytics pipelines.

## Inspection state

Call ``RemoteConfigStore/RemoteConfigStore/inspectionState()`` to inspect the cached snapshot, freshness, and refresh activity.

```swift
let state = try await store.inspectionState()

if state.isRefreshInFlight {
    print("Refresh is active.")
}

print("Freshness:", state.freshness as Any)
```

Inspection does not trigger network work.
