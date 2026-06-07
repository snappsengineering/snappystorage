# Collection storage layouts

SnappyStorage supports multiple **on-disk layouts** for `Service<T>` collections. Pick per collection — habits may stay monolith; activity history may shard or chunk.

Display **order is a UI concern** (sort/filter in the view model). On disk we optimize for **identity, lookup, and I/O unit size**.

## Layouts

| Layout | On disk | Best for | Partial read | Disk efficiency |
|--------|---------|----------|--------------|-----------------|
| **monolith** | `Activity.json` — one JSON array | Small collections, tiny rows | Load all | Best |
| **chunked** | `Activity/chunk_000.json`, … | Medium collections, balanced | Load one chunk | Good |
| **perRecord** | `Activity/records/{id}.json` | Large rows, detail-only access | Load one record | Worst for tiny rows |
| **automatic** | Starts monolith; migrates when thresholds exceeded | Apps that may grow | After migration | Adaptive |

### Monolith (default today)

```
Documents/Activity.json   →   [ { id, ... }, { id, ... } ]
```

- One encrypt/decrypt + decode on full load.
- One rewrite on any save (unless debounced in app).
- **Use when:** file stays under ~256 KB or a few hundred small records.

### Chunked (best of both worlds)

```
Documents/Activity/
  manifest.json      // optional: ids → chunk index, lightweight list metadata
  chunk_000.json     // [ up to N items ]
  chunk_001.json
```

- **Few files** → less APFS block waste than per-record.
- **Partial read** → load `manifest` + one chunk for a screenful, or scan chunks until `fetch(id:)` hits.
- **Partial write** → re-encrypt/rewrite one chunk on save.
- **Use when:** hundreds–thousands of small/medium records; you want faster saves without hundreds of 4 KB allocations.

Suggested defaults: **50 items or 256 KB per chunk** (whichever comes first).

### Per-record

```
Documents/Activity/
  index.json           // optional summaries for list UI
  records/a1b2.json
  records/c3d4.json
```

- True **O(1) I/O** per save/load for one item.
- **Use when:** payloads are large (nested sets, blobs) or detail screens dominate.
- **Avoid when:** rows are tiny (habits, favorites) — block rounding wastes space.

### Automatic

```swift
CollectionLayout.automatic(
    CollectionLayoutThresholds(
        maxMonolithBytes: 256_000,
        maxMonolithItems: 500
    )
)
```

1. New installs: monolith.
2. On open, if file exceeds thresholds → one-time migration to chunked (or perRecord if configured).
3. Keep `Activity.json.bak` until migration flag is set.

## Encryption

Encryption is **per physical file**, same `Encryption` / Keychain key as today:

| Layout | Encrypt unit |
|--------|----------------|
| monolith | whole `Activity.json` |
| chunked | each `chunk_NNN.json` (+ optional `manifest.json`) |
| perRecord | each `records/{id}.json` (+ optional `index.json`) |

- **Cold load list:** decrypt manifest/index only (small).
- **Open detail:** decrypt one record/chunk.
- **Save one item:** re-seal only the chunk or record file that changed.
- GCM nonce is per file per write (same as monolith).

## In-memory model (all layouts)

Regardless of disk layout, `Service` keeps an **id-unique in-memory `Set<T>`** for O(1) membership semantics after load. UI receives **`Set<T>` via `fetchAll()`** — **order undefined**; view model sorts into `[T]` for display.

On disk, monolith layout may encode a JSON **array**; that order is not part of the Service contract.

## Migration between layouts

```
layoutVersion in manifest or UserDefaults
  v1 monolith JSON array
  v2 chunked directory
  v3 per-record directory (optional future)
```

Migration steps (library-owned, run once at launch):

1. Read old monolith (decrypt if needed).
2. Write new layout.
3. Set `layoutVersion`; optionally delete or rename old file.

Apps pass `CollectionLayout` at `Service` init; default `.monolith` preserves current behavior.

## Choosing a layout

| App / collection | Suggested layout |
|------------------|------------------|
| Retoxifier `Habit` | `.monolith` or `.automatic` |
| Workd `Favorite` | `.monolith` |
| Workd `Activity` (long history) | `.automatic` → chunked |
| Schmoozy `Card` / `Credential` | `.monolith` |
| Encrypted photo blobs | `.perRecord` or raw `Storage.storeData` |

When in doubt: **monolith + in-memory id map** until profiling shows slow saves or large files; then **chunked**, not per-record, unless rows are huge.
