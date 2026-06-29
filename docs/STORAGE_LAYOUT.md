# Collection storage layouts

SnappyStorage supports multiple **on-disk layouts** for `Service<T>` collections. Pick per collection — habits may stay on the default single-file layout; activity history may shard or chunk.

**Framework rules:** `CODING_STANDARDS.md` Rule 14 — `Layout` in `Data/`; `Destination` + `File` + `Location` resolve paths; internal `Storage` reads/writes bytes (sync); `Service` + `Payload` encode/encrypt and own the in-memory cache.

Display **order is a UI concern** (sort/filter in the view model). On disk we optimize for **identity, lookup, and I/O unit size**.

## Layouts

| Layout | On disk | Best for | Partial read | Disk efficiency |
|--------|---------|----------|--------------|-----------------|
| **default** | `Activity.json` — one JSON array | Small collections, tiny rows | Load all | Best |
| **chunked** | `Activity/chunk_000.json`, … | Medium collections, balanced | Load one chunk | Good |
| **perRecord** | `Activity/records/{id}.json` | Large rows, detail-only access | Load one record | Worst for tiny rows |
| **automatic** | Starts default; migrates when thresholds exceeded | Apps that may grow | After migration | Adaptive |
| **partitioned** *(future)* | `Activity/2024-08.json`, … by attribute range | Time-scoped history (e.g. monthly logs) | Load one partition | Good for month queries |

### Default (shipped today)

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
Layout.automatic(AutomaticThresholds())
```

1. New installs: default single-file layout.
2. On open, if file exceeds thresholds → one-time migration to chunked (or perRecord if configured).
3. Keep `Activity.json.bak` until migration flag is set.

## Encryption

Encryption is **per physical file**, same `Encryption` / Keychain key as today:

| Layout | Encrypt unit |
|--------|----------------|
| default | whole `Activity.json` |
| chunked | each `chunk_NNN.json` (+ optional `manifest.json`) |
| perRecord | each `records/{id}.json` (+ optional `index.json`) |

- **Cold load list:** decrypt manifest/index only (small).
- **Open detail:** decrypt one record/chunk.
- **Save one item:** re-seal only the chunk or record file that changed.
- GCM nonce is per file per write (same as default layout).

## In-memory model (all layouts)

Regardless of disk layout, `Service` keeps an **id-unique in-memory `Set<T>`** for O(1) membership semantics after load. UI receives **`Set<T>` via `fetchAll()`** — **order undefined**; view model sorts into `[T]` for display.

On disk, the default layout encodes a JSON **array**; that order is not part of the Service contract.

## Migration between layouts

```
layoutVersion in manifest or UserDefaults
  v1 default JSON array
  v2 chunked directory
  v3 per-record directory (optional future)
  v4 partitioned by attribute range (e.g. calendar month)
```

Migration steps (library-owned, run once at launch):

1. Read old default file (decrypt if needed).
2. Write new layout.
3. Set `layoutVersion`; optionally delete or rename old file.

Only `Layout.default` is implemented today — other layouts throw `unsupportedLayout` until wired. `Service` init does not take a layout parameter yet; `Location` uses `.default` internally.

## Choosing a layout

| App / collection | Suggested layout |
|------------------|------------------|
| Retoxifier `Habit` | `.default` or `.automatic` |
| Workd `Favorite` | `.default` |
| Workd `Activity` (long history) | `.automatic` → chunked, or **`.partitioned`** (by month) — see below |
| Schmoozy `Card` / `Credential` | `.default` |
| Encrypted photo blobs | `.perRecord` or app-managed binary via `Service` / custom path |

When in doubt: **default layout + in-memory id map** until profiling shows slow saves or large files; then **chunked**, not per-record, unless rows are huge.

## Partitioned by attribute range (future)

**Not implemented.** Splits files by a **semantic key** on the model (e.g. calendar month), not by item count like `chunked`.

```
Documents/Activity/
  2024-07.json    →  [ entries in July ]
  2024-08.json    →  [ entries in August ]
  2024-09.json
```

| Layout | Splits by |
|--------|-----------|
| `chunked` | Count / bytes (`chunk_000`, `chunk_001`) |
| `partitioned` | Model attribute (`2024-08`, fiscal quarter, etc.) |
| `perRecord` | `id` |

### Why

- I/O matches **queries** (“August only”, “drop old years”) without scanning every chunk.
- Partial write: re-seal one month file on save when the partition key is known.

### Planned API shape

```swift
// Layout (where) — file naming strategy
case partitioned(PartitionPolicy)

public struct PartitionPolicy: Equatable, Sendable {
    public enum Granularity: Equatable, Sendable {
        case calendarMonth   // Activity/2024-08.json
        case calendarYear
        case calendarWeek
    }
    public var granularity: Granularity
}
```

**Partition key (what / how)** — not stored on `Layout` (needs type info):

- **Option A:** `protocol Partitionable: Storable { var partitionDate: Date { get } }`
- **Option B:** `partitionKey: (T) -> String` on `Service` init
- **Option C:** `var partitionKey: String` on model (app computes `"2024-08"`)

Path resolution on **`Location`**: `fileURL(partitionKey:)` → `base/2024-08.json`.

**Service (how):**

- **Eager (v1):** load all partition files into `Set<T>` — same public API as today.
- **Lazy (later):** `fetch(matching: QuerySpec)` loads only relevant partitions.

### vs existing cases

- Do **not** overload `chunked(ChunkPolicy)` with date logic — different bucketing rules.
- `automatic` may migrate default → partitioned-by-month when size or access patterns warrant it.

See [FUTURE_IMPROVEMENTS.md](FUTURE_IMPROVEMENTS.md) § Partitioned layout.
