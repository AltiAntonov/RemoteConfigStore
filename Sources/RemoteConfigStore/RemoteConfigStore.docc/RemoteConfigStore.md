# ``RemoteConfigStore``

Offline-first remote configuration caching with TTL, stale fallback, and typed keys.

## Overview

`RemoteConfigStore` helps Apple apps read remote configuration values without rebuilding caching and fallback behavior from scratch. The package keeps the remote fetch step separate from local caching policy, so you can plug in your own backend client while still getting:

- in-memory and on-disk caching
- configurable freshness windows
- optional stale fallback during offline or degraded network periods
- typed keys and primitive accessors for safer reads
- explicit read policies for cache-first, refresh-first, and stale-while-revalidate style behavior

The package is centered on a few public types:

- ``RemoteConfigStore/RemoteConfigStore``
- ``RemoteConfigFetcher``
- ``RemoteConfigSnapshot``
- ``RemoteConfigKey``
- ``RemoteConfigValue``
- ``ReadPolicy``

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:ReadPolicies>

### Core Types

- ``RemoteConfigStore/RemoteConfigStore``
- ``RemoteConfigFetcher``
- ``RemoteConfigSnapshot``
- ``RemoteConfigKey``
- ``ReadPolicy``
- ``RemoteConfigStoreError``
