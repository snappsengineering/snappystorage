# SnappyStorage

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2018%20%7C%20macOS%2015%20%7C%20tvOS%2018%20%7C%20watchOS%2011-lightgrey.svg)](#requirements)
[![CI](https://github.com/snappsengineering/snappystorage/actions/workflows/ci.yml/badge.svg)](https://github.com/snappsengineering/snappystorage/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Local-first persistence for Swift apps. File-backed JSON storage with optional AES-GCM encryption. Replaces scattered `UserDefaults` and manual `FileManager` code. 100% line coverage, CI-gated.

## Requirements

Swift 6.0+, iOS 18 / macOS 15 / tvOS 18 / watchOS 11.

## Installation

```swift
.package(url: "https://github.com/snappsengineering/snappystorage.git", from: "2.0.0")
```

## Services

| Service | Use for |
|---|---|
| `Service<T>` | Synchronous `Set<T>` collection, one JSON file per collection |
| `PublishedService<T>` | Same, with `@Published` for SwiftUI / Combine |
| `ActorService<T>` | Actor-isolated async API with `AsyncStream` updates (`T: Sendable`) |
| `SingleValueService<T>` | Any single `Codable` value (replaces `UserDefaults`) |
| `BlobService` | Raw `Data` (PDFs, images) that isn't `Storable` |

`Service`, `PublishedService`, `SingleValueService` are not thread-safe on their own. Call from one queue (e.g. `@MainActor`) or use `ActorService`.

## Quick start

Models conform to `Storable` (`id: String`, `Codable`, `Hashable`; equality and hashing default to `id`):

```swift
struct Note: Storable {
    var id: String = Note.generateHexID()
    var title: String
    var body: String
}
```

### Collections

```swift
let notes = Service<Note>()

notes.save(note)                      // or save(Set<Note>)
notes.delete(note)                    // or delete(Set<Note>)
notes.replace([a, b])                 // swap whole collection
notes.batch { $0.insert(c); $0.remove(a) }   // one write
let all = notes.fetchAll()
let one = notes.fetch(id: "abc123")
```

`count` and `fetch(id:)` are O(1). `unload()` drops the in-memory copy; the next access reloads from disk.

### Errors never crash

A corrupt or undecryptable file leaves the collection empty and the file untouched:

```swift
if let error = notes.loadError { print("load failed: \(error)") }
// notes.lastError reports the most recent persist failure
```

### Single value

```swift
let config = SingleValueService<AppConfig>(fileName: "AppConfig")
try config.save(AppConfig(theme: "dark", fontSize: 16))

config.fetch()        // AppConfig?, nil on missing OR corrupt file
try config.load()     // nil if never saved, throws if corrupt
```

### Async

```swift
let service = ActorService<Note>()
await service.save(note)
let all = await service.fetchAll()

for await update in service.updates { print("\(update.count) items") }
```

### Combine

```swift
let service = PublishedService<Note>()   // service.$published: Publisher<Set<Note>, Never>
```

### Blobs

```swift
let blob = BlobService(destination: .local(.applicationSupportDirectory),
                       fileName: "receipt-1", fileExtension: "pdf")
try blob.storeData(pdfData)
let data = try blob.fetchData()
try blob.remove()
```

### Encryption

```swift
let service = Service<Note>(encryption: Encryption(key: Encryption.generateKey()))

// Keychain-backed key, persisted per app
let store = KeychainKeyStore.forApp(bundleIdentifier: "com.example.app")
let keyed = Service<Note>(encryption: try Encryption(keychain: store))
```

## Destinations

```swift
Service<Note>(destination: .local(.documentDirectory))   // default
Service<Note>(destination: .local(.applicationSupportDirectory))
Service<Note>(destination: .iCloud)                       // ubiquity container
Service<Note>(destination: .custom("/absolute/path"))
```

| Destination | Backed up | User-visible | Use for |
|---|---|---|---|
| `.documentDirectory` | Yes | Files app | User-created content (notes, photos, exports) |
| `.applicationSupportDirectory` | Yes | No | App state, credentials, internal data |
| `.cachesDirectory` | No, OS may purge | No | Rebuildable data only. Never irreplaceable data |
| `.iCloud` | iCloud Drive sync | iCloud Drive | Cross-device sync |

## Example app

`Example/SnappyStorageDemo.xcodeproj` demos sync, Combine, async, and encrypted storage in a runnable iOS app.

## Roadmap

Chunked / partitioned layouts, query layer, and migration decode are design-only: see [docs/FUTURE_IMPROVEMENTS.md](docs/FUTURE_IMPROVEMENTS.md) and [docs/STORAGE_LAYOUT.md](docs/STORAGE_LAYOUT.md). Release notes: [CHANGELOG.md](CHANGELOG.md).

## License

MIT
