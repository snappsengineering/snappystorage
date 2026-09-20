import Foundation
import os

public actor ActorService<T: Storable & Sendable> {

    // MARK: - Properties

    private let persistence: Persistence
    private static var logger: Logger { Logger(subsystem: "com.snappsengineering.snappystorage", category: "\(T.self)") }

    private var _collection: Set<T>?
    private var index: [String: T] = [:]
    private let continuation: AsyncStream<Set<T>>.Continuation

    /// Set when the on-disk file exists but failed to load (corrupt data, wrong encryption key).
    /// The file is left untouched; `collection` starts empty so the app doesn't crash.
    public private(set) var loadError: Error?

    /// Stream of collection snapshots. Yields an empty set at `init` (no disk read has happened
    /// yet, since loading is lazy), then yields the true loaded collection as soon as any
    /// read or write path triggers the first load.
    public let updates: AsyncStream<Set<T>>

    // MARK: - Lifecycle

    public init(
        destination: Destination = .local(.documentDirectory),
        fileName: String? = nil,
        fileExtension: String = "json",
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = JSONDecoder(),
        encryption: Encryption? = nil
    ) {
        self.persistence = Persistence(
            destination: destination,
            fileName: fileName ?? "\(T.self)",
            fileExtension: fileExtension,
            encoder: jsonEncoder,
            decoder: jsonDecoder,
            encryption: encryption
        )
        let (stream, continuation) = AsyncStream<Set<T>>.makeStream(bufferingPolicy: .bufferingNewest(1))
        self.updates = stream
        self.continuation = continuation
        continuation.yield([])
    }

    deinit {
        continuation.finish()
    }

    // MARK: - Read

    public func fetchAll() -> Set<T> {
        loadIfNeeded()
        return _collection ?? []
    }

    public func fetch(id: String) -> T? {
        loadIfNeeded()
        return index[id]
    }

    /// The number of items in the collection. Triggers the same lazy load as `fetchAll()`.
    public var count: Int {
        loadIfNeeded()
        return index.count
    }

    // MARK: - Write

    public func save(_ item: T) {
        loadIfNeeded()
        loadedCollection.upsert(item)
        index[item.id] = item
        persist()
    }

    public func save(_ items: Set<T>) {
        loadIfNeeded()
        items.forEach {
            loadedCollection.upsert($0)
            index[$0.id] = $0
        }
        persist()
    }

    public func delete(_ item: T) {
        loadIfNeeded()
        loadedCollection.remove(item)
        index.removeValue(forKey: item.id)
        persist()
    }

    public func delete(_ items: Set<T>) {
        loadIfNeeded()
        items.forEach {
            loadedCollection.remove($0)
            index.removeValue(forKey: $0.id)
        }
        persist()
    }

    /// Replaces the entire collection with `items` (a full swap, not a merge), then persists once.
    public func replace(_ items: Set<T>) {
        loadedCollection = items
        rebuildIndex()
        persist()
    }

    /// Passes a mutable copy of the current collection to `changes` for freeform add/remove/mutate,
    /// assigns the result back, then persists once — regardless of how many items `changes` touches.
    public func batch(_ changes: (inout Set<T>) -> Void) {
        loadIfNeeded()
        var updated = loadedCollection
        changes(&updated)
        loadedCollection = updated
        rebuildIndex()
        persist()
    }

    // MARK: - File management

    public func removeFile() throws {
        try persistence.remove()
    }

    /// Drops the in-memory collection and index back to an un-loaded state. The next access to
    /// `fetchAll()`, `fetch(id:)`, `count`, or any write method re-triggers a load from disk.
    public func unload() {
        _collection = nil
        index = [:]
        loadError = nil
    }

    // MARK: - Private

    /// Mutable access to the loaded collection. Callers must call `loadIfNeeded()` first
    /// (or be in a path, like `replace`, that intentionally overwrites without reading).
    private var loadedCollection: Set<T> {
        get { _collection ?? [] }
        set { _collection = newValue }
    }

    private func loadIfNeeded() {
        guard _collection == nil else { return }
        let (collection, error) = Self.load(persistence: persistence)
        _collection = collection
        loadError = error
        rebuildIndex()
        continuation.yield(collection)
    }

    private func rebuildIndex() {
        index = Dictionary(uniqueKeysWithValues: (_collection ?? []).map { ($0.id, $0) })
    }

    private func persist() {
        try? persistence.write(Array(_collection ?? []))
        continuation.yield(_collection ?? [])
    }

    private static func load(persistence: Persistence) -> (Set<T>, Error?) {
        do {
            let items: [T] = try persistence.read([T].self)
            return (Set(items), nil)
        } catch StorageError.fileDoesNotExist {
            return ([], nil)
        } catch {
            logger.warning("SnappyStorage failed to load collection, starting empty: \(error.localizedDescription)")
            return ([], error)
        }
    }
}
