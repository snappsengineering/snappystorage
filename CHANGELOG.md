# Changelog

## Unreleased

_Nothing yet._

## 2.0.0

### Removed

- `PublishedSingleValueService` — zero consumers, duplicate of the `PublishedService` pattern for a different base.
- `Layout`, `ChunkPolicy`, `AutomaticThresholds`, `CollectionLayout` — unimplemented (3 of 4 cases threw at runtime), zero consumers. Design preserved in `docs/STORAGE_LAYOUT.md`; will return once chunked/perRecord storage actually ships.
- `ServiceBacking`, `Payload` — folded into internal `Persistence`.
- `EncryptionError.keyGenerationFailed`, `FileManager.modificationDate(at:)` — dead code.
- `AsyncStorage`, `SingleValueService.exists`, `Storage.lastUpdated`, `Destination.makeURL` (already absent) — confirmed gone.

### Changed

- `Storage`, `Location`, `File` dropped their phantom generic type parameter.
- `ActorService.updates` is now `public let` instead of a computed property; `ActorService` gained `deinit { continuation.finish() }`.
- `Storable.generateHexID(length:)` now actually respects `length` (previously always produced ≤6 hex digits of entropy regardless of the requested length).
- `Service.init` no longer `fatalError`s on a corrupt/undecryptable file. It starts with an empty collection, leaves the file untouched, and sets `loadError`.
- `Service` gained `open func collectionDidChange()`, called once after every successful `save`/`delete`. `PublishedService` now overrides this single hook instead of overriding `save`/`delete` three times each.
- `SingleValueService` gained `func load() throws -> T?`; `fetch()` keeps its old lenient behavior (`try? load()`).
- `Destination.cloud` renamed to `.iCloud`; `.cloud` kept as a `@available(*, deprecated)` alias for one release.

### Added

- `BlobService` — public raw-`Data` storage for blobs (PDFs, images) that don't fit the `Storable` JSON model. Replaces the `main`-branch public `Storage` class for that use case.
- `Service.loadError` / `Service.lastError` — surface load and persist failures instead of silently swallowing them.
- Test coverage: 100% line coverage (up from an unmeasured baseline), 104 tests. CI now gates merges on 100% `Sources/SnappyStorage` line coverage.
