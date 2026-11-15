# Collection storage layouts (design)

**Status:** design only. Today `Service<T>` always writes one JSON file per collection (`Activity.json`). Everything below is planned, not implemented.

Display order is a UI concern (sort in the view model). On disk we optimize for identity, lookup, and I/O unit size. `Service` keeps an id-unique in-memory `Set<T>` regardless of layout.

## Layouts

| Layout | On disk | Best for | Partial read |
|--------|---------|----------|--------------|
| **default** (shipped) | `Activity.json`, one JSON array | Small collections, tiny rows | No |
| **chunked** | `Activity/chunk_000.json`, ... | Hundreds to thousands of small/medium rows | One chunk |
| **perRecord** | `Activity/records/{id}.json` | Large rows, detail-only access | One record |
| **partitioned** | `Activity/2024-08.json`, ... by attribute | Time-scoped history | One partition |
| **automatic** | Starts default, migrates past thresholds | Collections that may grow | After migration |

### Chunked

```
Activity/
  manifest.json      // optional: ids -> chunk index, list metadata
  chunk_000.json     // up to N items
  chunk_001.json
```

- Few files: less APFS block waste than per-record.
- Partial read and write: load or re-encrypt one chunk.
- Suggested defaults: 50 items or 256 KB per chunk, whichever first.

### Per-record

```
Activity/
  index.json         // optional summaries for list UI
  records/a1b2.json
```

- O(1) I/O per item. Avoid for tiny rows (block rounding wastes space).

### Partitioned by attribute range

Splits by a semantic key (e.g. calendar month), not by count or id.

```
Activity/
  2024-07.json
  2024-08.json
```

- I/O matches queries ("August only", "drop old years").
- Partition key options: `protocol Partitionable { var partitionDate: Date }`, a `partitionKey: (T) -> String` closure on `Service` init, or a model-computed `String`.
- Planned `PartitionPolicy` granularity: `.calendarMonth`, `.calendarYear`, `.calendarWeek`.
- Eager load first (same public API); lazy partition loading once a query layer exists.
- Do not overload `chunked` with date logic.

### Automatic

New installs use default. On open, if the file exceeds thresholds, migrate once to chunked (or perRecord) and keep `Activity.json.bak` until a migration flag is set.

## Encryption

Encryption is per physical file, using the same `Encryption` / Keychain key as today. Each chunk, record, or partition is sealed separately with a fresh GCM nonce per write, so saving one item re-seals only its file. A manifest/index can be decrypted alone for cold list loads.

## Migration between layouts

Track a `layoutVersion` (manifest or UserDefaults): v1 default, v2 chunked, v3 perRecord, v4 partitioned. Library-owned, once at launch: read the old layout (decrypt), write the new one, set the version, delete or rename the old file.

## Choosing

Default layout until profiling shows slow saves or large files; then chunked (not perRecord unless rows are huge); partitioned for time-series history.
