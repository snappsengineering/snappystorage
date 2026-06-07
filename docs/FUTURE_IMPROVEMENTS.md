# SnappyStorage — Future Improvements

Local note. Last updated: 2026-06-07 (query/predicate section added).

## API principle: Set at Service level

**Keep `Set<T>` notation at the Service public API.** Do not expose `[T]` from `fetchAll()`, `collection`, or bulk `save`/`replace` on `Service`, `PublishedService`, or `ActorService`.

| Layer | Type | Notes |
|-------|------|-------|
| **Service API** | `Set<T>` | Unique by `Storable.id`; unordered |
| **Storage / disk** | `[T]` JSON (monolith) | Encode/decode array internally; order not guaranteed to callers |
| **App ViewModels** | `[T]` | Sort, filter, section for UI |

`feature/array-backed-collections` may use array encoding on disk for order-preserving persistence — that must stay **internal to Storage**. When merging that branch, restore or preserve **`Set<T>` on Service** (as on `main` today).

---

## Outstanding branches

### `feature/array-backed-collections` (local + origin)

**Ahead of `main` by 2 commits (not merged):**

| Commit | Summary |
|--------|---------|
| `bde15b7` | Replace `Set<T>` with `[T]` for order-preserving collections |
| `877d6b5` | Fallback to plaintext on decrypt failure in `readData()` |

**Uncommitted on branch:**

- `CollectionLayout.swift`, `CollectionLayoutTests.swift`
- `docs/STORAGE_LAYOUT.md`
- `README.md` updates

**Before merge:**

- [ ] **Revert or refactor Service public API back to `Set<T>`** if branch currently exposes `[T]`
- [ ] Keep array backing inside `Storage` only (encode/decode JSON array without changing Service contract)
- [ ] Wire `CollectionLayout` into `Service` / `Storage`
- [ ] Revisit decrypt fallback — see **Strict decrypt** below
- [ ] Update Example app; full test suite

### `main`

- `09c1b3c` — initial release; **`Set<T>` Service API**
- **Ledger** pins to `main` until branch merge preserves Set API

---

## Ledger-driven improvements

| Item | Priority | Notes |
|------|----------|-------|
| **`FileStorage` public API** | Medium | README mentions it; use `Storage.storeData` or add wrapper |
| **`BlobDirectoryStore`** | Medium | Encrypted PDF directory helper |
| **Strict decrypt mode** | High | Fail closed instead of returning raw bytes on decrypt failure |
| **Keychain key helper** | Low | Optional; Ledger uses LedgerCore `KeychainKeyStore` for now |

---

## Workd & Schmoozy optimization

From `docs/STORAGE_LAYOUT.md`:

| App | Collection | Layout |
|-----|------------|--------|
| Schmoozy | `Card`, `Credential` | `.monolith` |
| Workd | `Favorite` | `.monolith` |
| Workd | `Activity` (long history) | `.automatic` → chunked |

Schmoozy: migrate `LocalStorageService` → `Service<T>` behind feature flag; preserve `Application Support` paths and backward compatibility.

Workd: Activity history benefits most from chunked partial writes; ViewModels sort `Set<Activity>` for timeline UI.

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

- [ ] Public `FileStorage` / `BlobDirectoryStore`
- [ ] Strict decrypt flag
- [ ] Surface `persist()` errors instead of `try?`
- [ ] README: planned vs shipped APIs
- [ ] Example app sync with encryption + layouts

## Suggested merge order

1. Fix **Set-at-Service** on `feature/array-backed-collections`, then merge to `main`
2. FileStorage wrapper + strict decrypt decision
3. CollectionLayout (chunked); pilot Workd Activity
4. Schmoozy monolith pilot behind feature flag

## References

- [STORAGE_LAYOUT.md](STORAGE_LAYOUT.md)
- [Ledger plan](~/.cursor/plans/statement_pdf_parser_45618ca2.plan.md) — Set at Service section
- [schmoozy/ARCHITECTURE.md](../../schmoozy/ARCHITECTURE.md)
