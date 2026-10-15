# Changelog

## Unreleased

_Nothing yet._

## 2.0.0

### Breaking

- `ActorService.init` no longer throws. A corrupt/undecryptable file leaves the collection empty, the file untouched, and sets `ActorService.loadError` (same soft-fail as `Service`).
- `Destination.cloud` alias removed. Use `.iCloud`.

### Added

- Batch API on `Service` and `ActorService`: `delete(Set<T>)`, `replace(_:)`, `batch(_:)`. Each persists once.
- O(1) id index: `fetch(id:)` and `count`.
- Lazy load: `unload()` drops the in-memory collection; next access reloads from disk.
- Concurrency and fuzz-style round-trip tests.
- 100% line coverage (116 tests), CI-gated.

## 1.0.0

### Removed

- `PublishedSingleValueService` (no consumers).
- `Layout`, `ChunkPolicy`, `AutomaticThresholds`, `CollectionLayout`: unimplemented, no consumers. Design kept in `docs/STORAGE_LAYOUT.md`.
- `ServiceBacking`, `Payload`: folded into internal `Persistence`.
- `AsyncStorage`, `SingleValueService.exists`, `Storage.lastUpdated`, `EncryptionError.keyGenerationFailed`, `FileManager.modificationDate(at:)`: dead code.

### Changed

- `Storage`, `Location`, `File` dropped their unused generic parameter. `Storage` is now internal.
- `ActorService.updates` is `public let`; `ActorService` finishes its stream on `deinit`.
- `Storable.generateHexID(length:)` now respects `length`.
- `Service.init` no longer `fatalError`s on a corrupt/undecryptable file: empty collection, file untouched, `loadError` set.
- `Service.collectionDidChange()` hook, called after every successful save/delete. `PublishedService` overrides it instead of overriding each write method.
- `SingleValueService.load() throws -> T?` added; `fetch()` stays lenient (`try? load()`).
- `Destination.cloud` renamed `.iCloud` (`.cloud` kept as a deprecated alias).

### Added

- `BlobService`: raw `Data` storage for PDFs/images that aren't `Storable`.
- `Service.loadError` / `Service.lastError`.
- 96.6% line coverage (67 tests).
