# Read Policies

Choose a read policy based on whether your caller prefers low latency, fresh values, or a balance of both.

## `immediate`

``ReadPolicy/immediate`` is the most cache-oriented mode.

- fresh cache: return immediately
- stale but still usable cache: return immediately
- no usable cache: wait for a refresh

Use it for fast UI reads and app startup flows where responsiveness matters more than forcing a refresh first.

## `refreshBeforeReturning`

``ReadPolicy/refreshBeforeReturning`` prefers fresh values when the cache is stale.

- fresh cache: return immediately
- stale cache: attempt a refresh first
- refresh failure with still-usable stale cache: return stale data
- refresh failure with no usable cache: throw

Use it when a flow should prefer the newest possible config but can still tolerate stale fallback when offline.

## `immediateWithBackgroundRefresh`

``ReadPolicy/immediateWithBackgroundRefresh`` behaves like stale-while-revalidate.

- fresh or stale-but-usable cache: return immediately
- trigger a background refresh if one is not already running
- no usable cache: wait for a refresh

Use it when you want instant reads while steadily nudging the cache toward freshness.

## Freshness windows

The store uses two related time windows:

- `ttl`: how long a fetched snapshot is considered fresh
- `maxStaleAge`: how long expired data can still be served as a fallback

That produces three states:

1. fresh
2. stale but usable
3. expired and unusable

If a snapshot is beyond both windows, the store must refresh or throw.
