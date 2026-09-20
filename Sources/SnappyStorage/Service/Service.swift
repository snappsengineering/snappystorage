import Foundation
import os

open class Service<T: Storable> {

    // MARK: - Properties

    private let persistence: Persistence
    private static var logger: Logger { Logger(subsystem: "com.snappsengineering.snappystorage", category: "\(T.self)") }

    private var _collection: Set<T>?
    private var index: [String: T] = [:]

    /// The in-memory collection. Loaded lazily from disk on first access (here, `fetchAll()`,
    /// `fetch(id:)`, `count`, or any write method) rather than eagerly in `init`.
    public var collection: Set<T> {
        loadIfNeeded()
        return _collection ?? []
    }

    /// The number of items in `collection`. Triggers the same lazy load as `collection`.
    public var count: Int {
        loadIfNeeded()
        return index.count
    }

    /// Set when the on-disk file exists but failed to load (corrupt data, wrong encryption key).
    /// The file is left untouched; `collection` starts empty so the app doesn't crash.
    public private(set) var loadError: Error?

    /// Set when the most recent `persist()` (triggered by `save`/`delete`) failed to write.
    public private(set) var lastError: Error?

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
    }

    // MARK: - Read

    public func fetchAll() -> Set<T> {
        collection
    }

    public func fetch(id: String) -> T? {
        loadIfNeeded()
        return index[id]
    }

    // MARK: - Write

    open func save(_ item: T) {
        loadIfNeeded()
        loadedCollection.upsert(item)
        index[item.id] = item
        persist()
    }

    open func save(_ items: Set<T>) {
        loadIfNeeded()
        items.forEach {
            loadedCollection.upsert($0)
            index[$0.id] = $0
        }
        persist()
    }

    open func delete(_ item: T) {
        loadIfNeeded()
        loadedCollection.remove(item)
        index.removeValue(forKey: item.id)
        persist()
    }

    open func delete(_ items: Set<T>) {
        loadIfNeeded()
        items.forEach {
            loadedCollection.remove($0)
            index.removeValue(forKey: $0.id)
        }
        persist()
    }

    /// Replaces the entire collection with `items` (a full swap, not a merge), then persists once.
    open func replace(_ items: Set<T>) {
        loadedCollection = items
        rebuildIndex()
        persist()
    }

    /// Passes a mutable copy of the current collection to `changes` for freeform add/remove/mutate,
    /// assigns the result back, then persists once — regardless of how many items `changes` touches.
    open func batch(_ changes: (inout Set<T>) -> Void) {
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

    public func reload() {
        let (collection, error) = Self.load(persistence: persistence)
        _collection = collection
        loadError = error
        rebuildIndex()
    }

    /// Drops the in-memory collection and index back to an un-loaded state. The next access to
    /// `collection`, `fetchAll()`, `fetch(id:)`, `count`, or any write method re-triggers a load
    /// from disk. Complements `reload()`, which re-reads eagerly; `unload()` defers the re-read.
    public func unload() {
        _collection = nil
        index = [:]
        loadError = nil
    }

    // MARK: - Change hook

    /// Called once after every successful `save`/`delete`. Override to react to changes —
    /// `PublishedService` mirrors `collection` into `@Published published` here.
    open func collectionDidChange() {}

    // MARK: - Internal

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
    }

    private func rebuildIndex() {
        index = Dictionary(uniqueKeysWithValues: (_collection ?? []).map { ($0.id, $0) })
    }

    func persist() {
        do {
            try persistence.write(Array(_collection ?? []))
            lastError = nil
        } catch {
            lastError = error
            Self.logger.warning("SnappyStorage persist failed: \(error.localizedDescription)")
        }
        collectionDidChange()
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
