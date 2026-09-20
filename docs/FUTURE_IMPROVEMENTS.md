# SnappyStorage — Future Improvements

Design notes for work that hasn't shipped yet. Everything here is optional reading for
contributors; nothing in this file is a promise about a specific release.

## Storable lifecycle metadata

Extend `Storable` (or a `StorableMetadata` mixin) with version-aware lifecycle fields:

| Property | Type | Notes |
|----------|------|-------|
| `introducedVersion` | `String` | App or SnappyStorage schema version when this record type (or field) was first introduced |
| `dateCreated` | `Date` | When the record was first persisted |
| `dropDate` | `Date?` | When the record type or field was retired from active use; `nil` = still live |

Use cases: migration tooling can skip or transform records/fields past their `dropDate`;
schema-drift auditing without ad-hoc per-model timestamps.

## Blob directory helper

`BlobService` covers one file per blob today. A `BlobDirectoryStore` that manages a whole
directory of blobs (list, prune by age, total size) would help apps with many detached
records (e.g. per-transaction receipts).

## Strict decrypt mode

Today, a corrupt or undecryptable file sets `Service.loadError` and starts empty — the file
is preserved untouched so nothing is lost. A future `strictDecrypt` option could instead make
initialization throw, for callers that would rather fail loudly than silently start empty.

## Partitioned layout (by attribute range)

**Status:** design only, not implemented. See [`STORAGE_LAYOUT.md`](STORAGE_LAYOUT.md) for the
full layout comparison (default / chunked / per-record / partitioned).

Split on-disk files by a **model attribute** (date month, year, week, or app-defined string
key) — not by chunk index or `id`:

```
Activity/2024-08.json   →  all Activity rows whose partition key is August 2024
```

Planned shape:

```swift
public struct PartitionPolicy: Equatable, Sendable {
    public enum Granularity: Equatable, Sendable {
        case calendarMonth, calendarYear, calendarWeek
    }
    public var granularity: Granularity
}
```

Partition key resolution (which field on `T` drives the bucket) is a `Service`-level concern,
not a `Layout` concern — keep `Layout`-equivalent types `Equatable`, no `KeyPath` on them.

## Bulk replace for collections

`Service`/`ActorService` have `save(_:)` for upsert but no full-array swap. A `replace(_
items: [T])` that clears and re-persists the whole collection in one write would help
call sites that pull a fresh full list from an API/sync source (e.g. snappycloud `pull()`)
and want to overwrite rather than merge. Explored on the (deleted)
`feature/array-backed-collections` branch alongside a `Set<T>` → `[T]` rewrite; the
`Set`→`[T]` part was rejected (breaking change, conflicts with the "keep `Set<T>` at
Service level" principle above), but `replace(_:)` itself doesn't require that rewrite —
it can be added as `collection = Set(items); persist()` without touching the public
collection type.

## Forgiving migration decode

Today, adding a new non-optional property to a `Storable` model breaks decoding of every
already-persisted file for that type until it's rewritten — there's no schema migration
story. Explored on the (deleted) `storage-alt` branch via a `MigrationDecoder` that merges
on-disk JSON with `T()` defaults before decoding (missing/null keys fall back to the
default). The idea is worth revisiting, but not the exact shape shipped there — it required
adding `init()` to the `Storable` protocol (source-breaking for every model) and did the
merge via `JSONSerialization` round-tripping. A lighter version — e.g. leaning on
`Decodable`'s `decodeIfPresent` per-property, or a `CodingKeys`-driven default-fill without
a protocol-wide `init()` requirement — would get the same migration safety without the
breaking change.

## Query / predicate layer

No shared query API exists today — consumers use named fetch methods and view-model-side
filtering. A future `QuerySpec<T>` (composable predicate + sort + optional limit) plus
`Service.query(_:)` would let apps replace ad hoc `fetchAll().filter { ... }` call sites with
a declarative, testable spec, and would open the door to partition-aware lazy loading once
partitioned layout ships.

## Suggested order

1. Strict decrypt mode (small, opt-in).
2. Chunked layout, piloted on one real, growing collection.
3. Partitioned layout (month buckets) — alternative/complement to chunked for time-series data.
4. Query/predicate layer, once there's a second layout to query against.

## References

- [STORAGE_LAYOUT.md](STORAGE_LAYOUT.md)
- [CHANGELOG.md](../CHANGELOG.md) for what's already shipped.
