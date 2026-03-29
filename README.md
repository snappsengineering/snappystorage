# SnappyStorage

Local-first persistence for Swift apps. File-backed JSON storage with optional encryption — a clean replacement for scattered `UserDefaults` and manual `FileManager` code.

## Features

- **Synchronous base layer** — `Storage`, `Service<T>`, `SingleValueService<T>`. No async, no Combine. Works everywhere.
- **Combine layer** — `PublishedService<T>`, `PublishedSingleValueService<T>`. `@Published` properties for SwiftUI / reactive UIKit.
- **Async/await layer** — `ActorService<T>`, `AsyncStorage`. Thread-safe actor-based service with `AsyncStream` updates.
- **Encryption** — Optional AES-GCM encryption via CryptoKit. Pass an `Encryption` instance to any storage or service.
- **File storage** — Raw `Data` read/write for binary blobs (images, exports, etc.).
- **Single value storage** — `SingleValueService<T>` replaces `UserDefaults` for any `Codable` value (structs, bools, strings).

## Requirements

- Swift 6.0+
- iOS 18+ / macOS 15+ / tvOS 18+ / watchOS 11+

## Installation

Add to your `Package.swift`:

```swift
// Track the main branch (always latest)
.package(url: "https://github.com/snappsengineering/snappystorage.git", branch: "main")
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
```

### Single value (replaces UserDefaults)

```swift
let configService = SingleValueService<AppConfig>(fileName: "AppConfig")

try configService.save(AppConfig(theme: "dark", fontSize: 16))
let config = configService.fetch() // AppConfig?
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

`ActorService` requires `T` to conform to `Sendable` (Swift 6); `struct` models with `String`/`Int`/etc. satisfy this automatically.

## Architecture

```
┌─────────────────────────────────────────────┐
│                   Your App                   │
├──────────┬──────────┬───────────────────────┤
│ Service  │ Published│ ActorService          │
│          │ Service  │ (async/await + stream) │
│ Single   │ Published│                       │
│ Value    │ Single   │ AsyncStorage          │
│ Service  │ Value    │                       │
├──────────┴──────────┴───────────────────────┤
│                  Storage                     │
│          (file I/O, JSON, encryption)        │
├──────────────────────────────────────────────┤
│   Storable  │  Destination  │  Encryption    │
└─────────────┴───────────────┴────────────────┘
```

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
Service<Note>(destination: .cloud)                               // iCloud ubiquity container
Service<Note>(destination: .custom("/absolute/path/to/folder"))
```

### Which directory should I use?

| Destination | Backed up | User-visible | Use for |
|---|---|---|---|
| `.documentDirectory` | ✅ iCloud backup | ✅ Files app | User-created content (notes, photos, exports) |
| `.applicationSupportDirectory` | ✅ iCloud backup | ❌ | App state, service data, credentials |
| `.cachesDirectory` | ❌ Purged by OS | ❌ | Derived/reconstructible data, thumbnails |
| `.cloud` | ✅ iCloud Drive sync | ✅ iCloud Drive | Cross-device sync |

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

Open `Example/SnappyStorageDemo.xcodeproj` in Xcode. It demonstrates all four layers in a runnable iOS app:

- **Sync tab** — `Service<T>` synchronous read/write
- **Combine tab** — `PublishedService<T>` with `@Published` automatic SwiftUI updates
- **Async tab** — `ActorService<T>` with `async/await` and `AsyncStream`
- **Encryption tab** — `SingleValueService<T>` for settings + `Service<T>` with AES-256-GCM encrypted photo storage

## License

MIT
