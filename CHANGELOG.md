# Changelog

All notable changes to `RemoteConfigStore` will be documented in this file.

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
