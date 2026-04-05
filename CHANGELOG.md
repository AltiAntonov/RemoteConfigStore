# Changelog

All notable changes to `RemoteConfigStore` will be documented in this file.

## 0.3.1

Refresh-result and unchanged-payload update.

### Added

- `RemoteConfigRefreshResult` to distinguish unchanged refreshes from updated payloads
- `refreshResult()` on `RemoteConfigStore`
- `hasSamePayload(as:)` on `RemoteConfigSnapshot`

### Changed

- refresh work now recognizes when a fetched snapshot has the same payload as the cached snapshot
- README now installs from `0.3.0` by default and shows the `refreshResult()` API

## 0.3.0

Built-in HTTP fetching release.

### Added

- `HTTPRemoteConfigRequest` for endpoint URL, headers, timeout, and request building
- `HTTPRemoteConfigFetcher` backed by `URLSession`
- `HTTPRemoteConfigFetcherError` for invalid HTTP response and payload failures
- convenience `RemoteConfigStore` initializer for URL-based HTTP configuration
- dedicated `HTTP Fetcher` example scenario in the showcase app

### Changed

- README quick start now includes the built-in HTTP path
- example app now covers both typed feature flags and HTTP-backed config loading

## 0.2.0

Developer ergonomics and documentation update.

### Added

- primitive convenience accessors on `RemoteConfigStore`
- matching typed convenience accessors on `RemoteConfigSnapshot`
- snapshot inspection helpers for age and freshness state
- first DocC catalog with getting-started and read-policy articles
- scenario-based example app shell with a dedicated `Feature Flags` showcase
- Swift Package Index manifest metadata for hosted documentation

### Changed

- README now explains when the package is a strong fit and where it is weaker
- README links directly to implemented example scenarios
- the example app root screen is now a scenario navigator instead of a single all-in-one demo view

### Fixed

- example usage now exercises typed-key access more directly instead of leaning on raw snapshot inspection
- package documentation and Swift Package Index metadata are aligned for public discovery

## 0.1.1

Repository metadata and release-follow-up update.

### Added

- repository code of conduct
- social preview image assets for GitHub presentation

### Changed

- GitHub Actions workflow updated for the Node 24 transition
- README now installs from the released `0.1.0` tag by default
- README includes a live CI workflow badge

### Fixed

- release documentation now matches the post-`0.1.0` public package state

## 0.1.0

Initial public release.

### Added

- offline-first remote configuration store with memory and disk cache layers
- typed keys and primitive remote config values
- TTL-based freshness and optional stale fallback via `maxStaleAge`
- three read policies for cache-first, refresh-first, and background-refresh reads
- injected fetcher protocol for backend integration
- example app demonstrating cache and refresh behavior
- Swift Testing coverage for cache behavior, store behavior, and failure paths

### Changed

- public API surface narrowed to the consumer-facing store, models, fetcher, policies, errors, and logging hooks

### Fixed

- concurrent refresh callers now share one in-flight refresh
- corrupted persisted cache files are treated as recoverable cache misses
