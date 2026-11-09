import Foundation

public actor ActorService<T: Storable & Sendable> {

  // MARK: - Properties

    private let persistence: Persistence
    private let configuration: ServiceConfiguration
    private static var logCategory: String { "\(T.self)" }

    private var _collection: Set<T>?
    private var index: [String: T] = [:]
    private let continuation: AsyncStream<Set<T>>.Continuation

    private var coalesceTask: Task<Void, Never>?

    public private(set) var loadError: Error?
    public private(set) var lastError: Error?

    public nonisolated let updates: AsyncStream<Set<T>>

  // MARK: - Lifecycle

    public init(
        destination: Destination = .local(.documentDirectory),
        fileName: String? = nil,
        fileExtension: String = "json",
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = JSONDecoder(),
        encryption: Encryption? = nil,
        configuration: ServiceConfiguration = ServiceConfiguration()
    ) {
        self.configuration = configuration
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

    public var loadState: CollectionLoadState {
        guard let collection = _collection else { return .notLoaded }
        if loadError != nil { return .failed }
        return collection.isEmpty ? .empty : .loaded(count: collection.count)
    }

  // MARK: - Load

    @discardableResult
    public func load() -> CollectionLoadState {
        loadIfNeeded()
        return loadState
    }

    public func preload() {
        loadIfNeeded()
    }

  // MARK: - Read

    public func fetchAll() -> Set<T> {
        loadIfNeeded()
        return _collection!
    }

    public func fetch(id: String) -> T? {
        loadIfNeeded()
        return index[id]
    }

    public var count: Int {
        loadIfNeeded()
        return index.count
    }

  // MARK: - Write

    public func save(_ item: T) {
        loadIfNeeded()
        loadedCollection.upsert(item)
        index[item.id] = item
        schedulePersist()
    }

    public func save(_ items: Set<T>) {
        loadIfNeeded()
        items.forEach {
            loadedCollection.upsert($0)
            index[$0.id] = $0
        }
        schedulePersist()
    }

    public func delete(_ item: T) {
        loadIfNeeded()
        loadedCollection.remove(item)
        index.removeValue(forKey: item.id)
        schedulePersist()
    }

    public func delete(_ items: Set<T>) {
        loadIfNeeded()
        items.forEach {
            loadedCollection.remove($0)
            index.removeValue(forKey: $0.id)
        }
        schedulePersist()
    }

    public func replace(_ items: Set<T>) {
        if _collection == nil {
            _collection = items
            loadError = nil
            index = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        } else {
            loadedCollection = items
            rebuildIndex()
        }
        schedulePersist(allowDespiteLoadFailure: true)
    }

    public func batch(_ changes: (inout Set<T>) -> Void) {
        loadIfNeeded()
        var updated = loadedCollection
        changes(&updated)
        loadedCollection = updated
        rebuildIndex()
        schedulePersist()
    }

    public func flush() {
        coalesceTask?.cancel()
        coalesceTask = nil
        guard _collection != nil else { return }
        performPersist(allowDespiteLoadFailure: false)
    }

    public func backupFile(suffix: String = "bak") throws -> URL? {
        try persistence.createBackup(suffix: suffix)
    }

    public func removeFile() throws {
        try persistence.remove()
    }

    public func unload() {
        _collection = nil
        index = [:]
        loadError = nil
    }

    public func setExactlyOne(_ item: T?) {
        batch { items in
            items = item.map { Set([$0]) } ?? []
        }
    }

    public func setDefaultItem(_ item: T) {
        batch { items in
            items.remove(item)
            items.insert(item)
        }
    }

    private var loadedCollection: Set<T> {
        get { _collection! }
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
        index = Dictionary(uniqueKeysWithValues: _collection!.map { ($0.id, $0) })
    }

    private func schedulePersist(allowDespiteLoadFailure: Bool = false) {
        let interval = configuration.persistCoalesceInterval
        guard let interval, interval > 0 else {
            performPersist(allowDespiteLoadFailure: allowDespiteLoadFailure)
            return
        }
        coalesceTask?.cancel()
        coalesceTask = Task {
            try? await Task.sleep(for: .seconds(interval))
            guard !Task.isCancelled else { return }
            performPersist(allowDespiteLoadFailure: allowDespiteLoadFailure)
        }
    }

    func persist() {
        schedulePersist()
    }

    private func performPersist(allowDespiteLoadFailure: Bool) {
        let blocked = loadError != nil && !allowDespiteLoadFailure
        let snapshot = _collection ?? []

        guard !blocked else {
            lastError = ServiceError.persistBlockedByLoadFailure
            StorageLog.warning("Skipping persist because the backing file failed to load; on-disk data preserved", category: Self.logCategory)
            continuation.yield(snapshot)
            return
        }

        do {
            try persistence.write(Array(snapshot))
            lastError = nil
        } catch {
            lastError = error
            StorageLog.warning("SnappyStorage persist failed: \(error.localizedDescription)", category: Self.logCategory)
        }
        continuation.yield(snapshot)
    }

    public func persistThrowing() throws {
        flush()
        if let lastError { throw lastError }
    }

    private static func load(persistence: Persistence) -> (Set<T>, Error?) {
        do {
            let items: [T] = try persistence.read([T].self)
            return (Set(items), nil)
        } catch StorageError.fileDoesNotExist {
            return ([], nil)
        } catch {
            StorageLog.warning("SnappyStorage failed to load collection, starting empty: \(error.localizedDescription)", category: "\(T.self)")
            return ([], error)
        }
    }
}
