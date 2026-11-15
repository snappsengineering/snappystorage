# SnappyStorage: Future Improvements

Design notes for unshipped work. Not a promise about any release.

## Storable lifecycle metadata

Version-aware fields on `Storable` (or a `StorableMetadata` mixin):

| Property | Type | Notes |
|----------|------|-------|
| `introducedVersion` | `String` | Schema/app version when the record type or field appeared |
| `dateCreated` | `Date` | When first persisted |
| `dropDate` | `Date?` | When retired; `nil` = live |

Enables migration tooling that skips/transforms retired records and schema-drift auditing.

## Blob directory helper

`BlobService` handles one file per blob. A `BlobDirectoryStore` managing a directory of blobs (list, prune by age, total size) would help apps with many detached records such as per-transaction receipts.

## Strict decrypt mode

Today a corrupt or undecryptable file sets `loadError` and starts empty, leaving the file untouched. A `strictDecrypt` option could make init throw instead, for callers who prefer failing loudly.

## Chunked / partitioned layouts

Design in [STORAGE_LAYOUT.md](STORAGE_LAYOUT.md). Pilot chunked on one real, growing collection first; partitioned (month buckets) suits time-series data.

## Forgiving migration decode

Adding a non-optional property to a `Storable` breaks decoding of existing files until rewritten. A prototype merged on-disk JSON with `T()` defaults before decoding, but required `init()` on `Storable` (source-breaking) and used `JSONSerialization` round-tripping. A lighter approach is preferable: per-property `decodeIfPresent`, or a `CodingKeys`-driven default fill, with no protocol-wide `init()`.

## Query / predicate layer

A `QuerySpec<T>` (predicate + sort + optional limit) with `Service.query(_:)` would replace ad hoc `fetchAll().filter { ... }` and enable partition-aware lazy loading once partitioned layout ships.
