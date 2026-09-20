# SnappyStorage

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2018%20%7C%20macOS%2015%20%7C%20tvOS%2018%20%7C%20watchOS%2011-lightgrey.svg)](#requirements)
[![CI](https://github.com/snappsengineering/snappystorage/actions/workflows/ci.yml/badge.svg)](https://github.com/snappsengineering/snappystorage/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Local-first persistence for Swift apps. File-backed JSON storage with optional encryption — a clean replacement for scattered `UserDefaults` and manual `FileManager` code.

## Features

- **Synchronous base layer** — `Service<T>`, `SingleValueService<T>`. Works everywhere.
- **Combine layer** — `PublishedService<T>`. `@Published` collection for SwiftUI / reactive UIKit.
- **Async/await layer** — `ActorService<T>`. Thread-safe actor-based service with `AsyncStream` updates.
- **Blob storage** — `BlobService` for raw `Data` (PDFs, images) that doesn't fit the `Storable` JSON model.
- **Encryption** — Optional AES-GCM via CryptoKit. Pass `Encryption` to any service, or `Encryption(keychain: KeychainKeyStore.forApp(...))` for keychain-backed keys.
- **Keychain keys** — `KeychainKeyStore` persists encryption keys per app (`Encryption(keychain:)`).
- **Single value storage** — `SingleValueService<T>` replaces `UserDefaults` for any `Codable` value (structs, bools, strings).
- **Soft-fail loading** — a corrupt or undecryptable file never crashes your app. `Service.loadError` / `Service.lastError` tell you what happened; the file itself is left untouched.

## Requirements

- Swift 6.0+
- iOS 18+ / macOS 15+ / tvOS 18+ / watchOS 11+

## Installation

Add to your `Package.swift`:

```swift
// Track a released version
.package(url: "https://github.com/snappsengineering/snappystorage.git", from: "2.0.0")
```

## Quick Start

### Collection storage

```swift
import SnappyStorage

// Service manages a Set<T> backed by a JSON file
let noteService = Service<Note>()

noteService.save(note)
noteService.delete(note)
let allNotes = noteService.fetchAll()
let note = noteService.fetch(id: "abc123")

// If the file existed but failed to load (corrupt data, wrong key),
// loadError is set and collection starts empty — the file is untouched.
if let error = noteService.loadError {
    print("Note storage failed to load: \(error)")
}
```

### Single value (replaces UserDefaults)

```swift
let configService = SingleValueService<AppConfig>(fileName: "AppConfig")

try configService.save(AppConfig(theme: "dark", fontSize: 16))
let config = configService.fetch() // AppConfig?, nil on missing OR corrupt file

// Or use load() to distinguish "never saved" (nil) from "corrupt" (throws) —
// useful when you'd otherwise overwrite an undecryptable file with a fresh default.
if let config = try configService.load() { /* ... */ }
```

### With encryption

```swift
let key = Encryption.generateKey()
let enc = Encryption(key: key)
let service = Service<Note>(encryption: enc)
```

### Combine (SwiftUI / reactive)

```swift
let service = PublishedService<Note>()
// service.$published is a Publisher<Set<Note>, Never>
```

### Async/await

```swift
let service = try ActorService<Note>()
await service.save(note)
let all = await service.fetchAll()

for await update in service.updates {
    print("Collection changed: \(update.count) items")
}
```

`ActorService` requires `T: Sendable` (Swift 6); `struct` models with `String`/`Int`/etc. satisfy this automatically. `Service`/`PublishedService`/`SingleValueService` are **not** thread-safe on their own — call them from one queue (e.g. `@MainActor`), or use `ActorService` for the actor-isolated async path.

### Blobs (PDFs, images — anything that isn't `Storable`)

```swift
let blobs = BlobService(destination: .local(.applicationSupportDirectory), fileName: "receipt-1", fileExtension: "pdf")
try blobs.storeData(pdfData)
let data = try blobs.fetchData()
try blobs.remove()
```

## Architecture

```
┌─────────────────────────────────────────────┐
│                   Your App                   │
├──────────┬──────────┬───────────────────────┤
│ Service  │ Published│ ActorService          │
│          │ Service  │ (async/await + stream) │
│ Single   │          │                       │
│ Value    │          │ BlobService           │
│ Service  │          │ (raw Data)            │
├──────────┴──────────┴───────────────────────┤
│      Persistence (encode/encrypt) ·          │
│         internal Storage (sync bytes)        │
├──────────────────────────────────────────────┤
│ Storable │ Destination │ Encryption          │
└──────────┴─────────────┴─────────────────────┘
```

### Source folders

| Folder | Role |
|--------|------|
| `Storable/` | App models (`Storable`) |
| `Location/` | `Destination`, `File`, `Location` (internal path resolution) |
| `Storage/` | `Storage` (internal byte I/O), `Persistence` (encode/encrypt) |
| `Service/` | `Service`, `ActorService`, `PublishedService`, `SingleValueService`, `BlobService` |
| `Encoder/` · `Encryption/` | JSON + AES-GCM + Keychain |

## Shipped vs planned

Everything above is shipped and tested (100% line coverage, CI-gated). Chunked/per-record/partitioned on-disk layouts and a query/predicate layer are **designed but not implemented** — see [`docs/FUTURE_IMPROVEMENTS.md`](docs/FUTURE_IMPROVEMENTS.md) and [`docs/STORAGE_LAYOUT.md`](docs/STORAGE_LAYOUT.md). `Service` always uses one JSON file per collection today.

## Conforming your model

```swift
import SnappyStorage

struct Note: Storable {
    var id: String = Note.generateHexID()
    var title: String
    var body: String
}
```

`Storable` requires `id: String`, `Codable`, and `Hashable`. Default implementations for `hash(into:)` and `==` are provided via equality on `id`.

## Destinations

```swift
Service<Note>(destination: .local(.documentDirectory))          // default
Service<Note>(destination: .local(.applicationSupportDirectory))
Service<Note>(destination: .iCloud)                              // iCloud ubiquity container
Service<Note>(destination: .custom("/absolute/path/to/folder"))
```

### Which directory should I use?

| Destination | Backed up | User-visible | Use for |
|---|---|---|---|
| `.documentDirectory` | ✅ iCloud backup | ✅ Files app | User-created content (notes, photos, exports) |
| `.applicationSupportDirectory` | ✅ iCloud backup | ❌ | App state, service data, credentials |
| `.cachesDirectory` | ❌ Purged by OS | ❌ | Derived/reconstructible data, thumbnails |
| `.iCloud` | ✅ iCloud Drive sync | ✅ iCloud Drive | Cross-device sync |

### Rule of thumb (why it matters)

Apple treats these locations differently for **backup**, **visibility**, and **lifecycle**. Picking the wrong one either confuses users (data they can’t find or export) or risks **silent data loss** when the OS reclaims space.

**Prefer `.documentDirectory` when the data is “the user’s stuff.”**  
That includes anything they authored (notes, images, exports) or would reasonably expect to keep if they reinstall the app or browse the Files app / iCloud Drive. iCloud backup includes this directory by default, so it fits data you cannot easily recreate.

**Use `.applicationSupportDirectory` for “how the app works,” not “what the user owns.”**  
Caches of structured app state, downloaded-but-internal configuration, credentials, or large databases the user does not open as files belong here. It is still backed up, but it is **not** exposed in the Files app, which signals “implementation detail.” That reduces accidental deletion and keeps the user-facing document area clean.

**Treat `.cachesDirectory` as explicitly disposable.**  
The system may delete its contents at any time when storage is low, and it is **not** backed up. Only store data you can rebuild (image thumbnails, HTTP caches, temp downloads). If losing a file would break the app or anger the user, do not put it in Caches.

**In practice:** default to **Documents** for user-created or user-facing persistence; use **Application Support** for internal state and secrets; never put **irreplaceable** data in **Caches**.

## Example

Open `Example/SnappyStorageDemo.xcodeproj` in Xcode. It demonstrates all layers in a runnable iOS app:

- **Sync tab** — `Service<T>` synchronous read/write
- **Combine tab** — `PublishedService<T>` with `@Published` automatic SwiftUI updates
- **Async tab** — `ActorService<T>` with `async/await` and `AsyncStream`
- **Encryption tab** — `SingleValueService<T>` for settings + `Service<T>` with AES-256-GCM encrypted photo storage

## License

MIT
