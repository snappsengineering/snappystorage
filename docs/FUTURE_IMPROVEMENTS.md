# SnappyStorage — Future Improvements

Local note. Last updated: 2026-06-28.

**Canonical rules:** `~/Documents/Apps/CODING_STANDARDS.md` **Rule 14** (triad) and **Rule 13** (attributes, proposed). Quick ref: `.cursor/rules/snappy-coding-standards.mdc`.

## Triad (Rule 14)

| Concern | Types | Public? |
|---------|--------|---------|
| **What** | `Storable` | Yes |
| **How** | `Service`, `ActorService`, `Payload` (encode/encrypt) | Service family yes |
| **Where (config)** | `Destination`, `Layout` | Yes (`Layout`; `typealias CollectionLayout`) |
| **Where (resolve)** | `File<T>`, `Location<T>`, `FileManager` extensions | No |
| **Where (I/O)** | `Storage<T>` — sync `read`/`write`/`remove` | No |

Flow: **Destination + File + Layout → Location → Storage (bytes)**. **Service** owns cache, CRUD, encode, encrypt. Public async = **`ActorService<T>`**.

## Source layout (`Sources/SnappyStorage/`)

| Folder | Contents |
|--------|----------|
| `Storable/` | `Storable` protocol |
| `Data/` | `Layout`, `ChunkPolicy`, `AutomaticThresholds` |
| `Location/` | `Destination`, `File`, `Location`, errors |
| `Storage/` | `Storage`, `StorageError` |
| `Service/` | `Service`, `ActorService`, `Published*`, `Payload`, `ServiceBacking` |
| `Encoder/` | `JSONCoding`, `EncoderError` |
| `Encryption/` | `Encryption`, `KeychainKeyStore`, errors |
| `FileManager+Extensions/` | resolve + I/O helpers, `Data.writeAtomic` |

## API principle: Set at Service level

**Keep `Set<T>` notation at the Service public API.** Do not expose `[T]` from `fetchAll()`, `collection`, or bulk `save`/`replace` on `Service`, `PublishedService`, or `ActorService`.

| Layer | Type | Notes |
|-------|------|-------|
| **Service API** | `Set<T>` | Unique by `Storable.id`; unordered |
| **Disk (via Payload)** | `[T]` JSON (default layout) | Encode/decode in Service layer; order not guaranteed to callers |
| **App ViewModels** | `[T]` | Sort, filter, section for UI |

`feature/array-backed-collections` may use array encoding on disk for order-preserving persistence — that must stay **internal to Payload/Service**, not on the public `Storage` API. When merging that branch, restore or preserve **`Set<T>` on Service** (as on `main` today).

---

## Outstanding branches

### `feature/array-backed-collections` (local + origin)

**Ahead of `main` by 2 commits (not merged):**

| Commit | Summary |
|--------|---------|
| `bde15b7` | Replace `Set<T>` with `[T]` for order-preserving collections |
| `877d6b5` | Fallback to plaintext on decrypt failure in `readData()` |

**Uncommitted on branch:**

- `Data/Layout.swift`, `LayoutTests.swift`
- `docs/STORAGE_LAYOUT.md`
- `README.md` updates

**Before merge:**

- [ ] **Revert or refactor Service public API back to `Set<T>`** if branch currently exposes `[T]`
- [ ] Keep array backing inside **Payload/Service** only (encode/decode JSON array without changing Service contract)
- [ ] Wire **`Layout`** into `Location` → `Storage` (default layout guard today); expose on `Service` init when chunked ships
- [ ] Revisit decrypt fallback — see **Strict decrypt** below
- [ ] Update Example app; full test suite

### `main`

- `09c1b3c` — initial release; **`Set<T>` Service API**
- **Ledger** pins to `main` until branch merge preserves Set API

---

## Storable lifecycle metadata

Extend `Storable` (or a `StorableMetadata` mixin) with version-aware lifecycle fields on top of `dateCreated`:

| Property | Type | Notes |
|----------|------|-------|
| **`introducedVersion`** | `String` | App or SnappyStorage schema version when this record type (or field) was first introduced |
| **`dateCreated`** | `Date` | When the record was first persisted (base metadata) |
| **`dropDate`** | `Date?` | When the record type or field was retired from active use; `nil` = still live |

Optional later: **`droppedVersion`** (`String?`) — app version that stopped writing or reading the field, paired with `dropDate` for migrations and strict-decrypt diagnostics.

Use cases:

- Migration tooling can skip or transform records/fields past their `dropDate`
- Support can see which app build introduced a shape (`introducedVersion`) vs when it was deprecated
- Ledger and Workd long-lived stores can audit schema drift without ad-hoc per-model timestamps

Not on `main` today — add when merging layout/migration work.

---

## Ledger-driven improvements

| Item | Priority | Notes |
|------|----------|-------|
| **Public raw-bytes API** | Low | Apps use `Service` / `SingleValueService`; `Storage` is internal sync I/O only |
| **`BlobDirectoryStore`** | Medium | Encrypted PDF directory helper |
| **Strict decrypt mode** | High | Fail closed instead of returning raw bytes on decrypt failure |
| ~~**Keychain key helper**~~ | — | **Shipped:** `KeychainKeyStore` + `Encryption(keychain:)` in `Encryption/` |

---

## Workd & Schmoozy optimization

From `docs/STORAGE_LAYOUT.md`:

| App | Collection | Layout |
|-----|------------|--------|
| Schmoozy | `Card`, `Credential` | `.default` |
| Workd | `Favorite` | `.default` |
| Workd | `Activity` (long history) | `.automatic` → chunked |

Schmoozy: migrate `LocalStorageService` → `Service<T>` behind feature flag; preserve `Application Support` paths and backward compatibility.

Workd: Activity history benefits most from chunked partial writes or **partitioned-by-month** (August entries in one file); ViewModels sort `Set<Activity>` for timeline UI.

---

## Partitioned layout (by attribute range)

**Status:** not implemented. Documented design for Rule 14 **where** layer.

Split on-disk files by a **model attribute** (date month, year, week, or app-defined string key) — not by chunk index or `id`.

### Example

```
Activity/2024-08.json   →  all Activity rows whose partition key is August 2024
```

Use case: Workd activity log — load/save/purge one month without touching other months.

### Planned types

| Piece | Owner | Notes |
|-------|--------|-------|
| `Layout.partitioned(PartitionPolicy)` | Where | `Granularity`: `.calendarMonth`, `.calendarYear`, `.calendarWeek` |
| `PartitionPolicy` | `Data/` or `Location/` | Equatable config only |
| Partition key on `T` | What / How | `Partitionable.partitionDate`, or `partitionKey: (T) -> String` on Service init |
| `Location.fileURL(partitionKey:)` | Where | `destination` + `file` base + `2024-08.json` |
| `Storage` | Where | Bytes at one partition URL (unchanged) |
| Load policy | How | v1: eager all partitions → `Set<T>`; later: query-scoped partition load |

### Tasks

- [ ] Add `PartitionPolicy` + `Layout.partitioned`
- [ ] `Partitionable` protocol (or Service init closure) for partition key
- [ ] `Location` multi-file path resolution; `usesDefaultFile == false`
- [ ] Service: route `save`/`delete` to correct partition file
- [ ] Migration: default → partitioned (optional, with `layoutVersion`)
- [ ] Pilot: Workd `Activity` with `.partitioned(.calendarMonth)` + `partitionDate`
- [ ] Docs + tests

### Do not

- Fold date bucketing into `chunked(ChunkPolicy)` — different semantics
- Put `KeyPath` on `Layout` enum — keep layout Equatable; key resolution stays on Service/Location

Details: [STORAGE_LAYOUT.md](STORAGE_LAYOUT.md) § Partitioned by attribute range.

---

## Query / predicate layer (later)

Workd and Retoxifier today use **named fetch methods** and **ViewModel-side filtering** — no shared query API:

| App | Service (implicit query cases) | ViewModel (display filters) |
|-----|----------------------------------|-----------------------------|
| **Workd** | `fetchActivities(for:)`, `fetchUniqueActivities()`, `fetchAll(with:)` | `ExerciseDBViewModel.SortMode` (recent / A–Z + search text) |
| **Retoxifier** | `fetchActiveHabits()`, `DailyHabitService.fetch(for:)` | `HabitBankViewModel` tab index (active / archived) |

**Goal:** mainstream a shared SnappyStorage query layer, plus optional **per-app query enums** that map cases → `QuerySpec` (the enum-on-service pattern Shane remembers — never shipped in git, but worth designing for).

### SnappyStorage (framework)

- [ ] **`QueryPredicate`** — composable filter (`&&`, `\|\|`, `!`, `equals`, `contains`, `id`)
- [ ] **`QuerySort` / `QuerySpec`** — predicate + sorts + optional limit
- [ ] **`QueryResult`** — `matching: Set<T>` + `ordered: [T]` for UI
- [ ] **`QueryEngine.run(_:on:)`** — pure executor over in-memory collection
- [ ] **`Service.query(_:)`** / **`fetch(matching:)`** — drop-in on `Service` / `ActorService`
- [ ] **Codable saved queries** — named presets (Ledger Phase 4)
- [ ] **Aggregate helpers** — sum/count on numeric key paths

### Per-app domain enums (app layer, not SnappyStorage)

Each app defines an enum for **screen-specific query cases**; each case builds a `QuerySpec`:

```swift
// Workd — replace ActivityService one-off fetch methods over time
enum ActivityQuery {
    case forDay(Date)
    case uniqueByName
    case named(String)
    case search(String, sort: ExerciseDBViewModel.SortMode)

    func spec() -> QuerySpec<Activity> { ... }
}

// Retoxifier — replace fetchActiveHabits / tab filtering
enum HabitQuery {
    case active
    case archived
    case all

    func spec() -> QuerySpec<Habit> { ... }
}
```

ViewModels call `activityService.query(ActivityQuery.forDay(date).spec()).ordered` instead of ad-hoc `fetchAll().filter`.

### Migration (when implemented)

- [ ] **Workd** — collapse `ActivityService` fetch helpers; keep `SortMode` in ViewModel or fold into `ActivityQuery`
- [ ] **Retoxifier** — replace `fetchActiveHabits()` and `HabitBankViewModel` tab switch with `HabitQuery`
- [ ] **Ledger** — `TransactionQuery` for month/debit/search presets

---

## Backlog

- [ ] **`Storable` lifecycle metadata** — `introducedVersion`, `dateCreated`, `dropDate` (see above)
- [ ] `BlobDirectoryStore` helper
- [ ] Strict decrypt flag
- [ ] Surface `persist()` errors instead of `try?`
- [ ] README: planned vs shipped APIs
- [ ] Example app sync with encryption + layouts
- [ ] **Partitioned layout** — `Layout.partitioned(PartitionPolicy)` by date month/year (see above)

## Suggested merge order

1. Fix **Set-at-Service** on `feature/array-backed-collections`, then merge to `main`
2. Strict decrypt decision
3. `Layout` chunked; pilot Workd Activity
4. **Partitioned layout** (month buckets) — alternative/complement to chunked for Activity
5. Schmoozy default-layout pilot behind feature flag

## References

- [STORAGE_LAYOUT.md](STORAGE_LAYOUT.md)
- [Ledger plan](~/.cursor/plans/statement_pdf_parser_45618ca2.plan.md) — Set at Service section
- [schmoozy/ARCHITECTURE.md](../../schmoozy/ARCHITECTURE.md)
