import Foundation

open class Service<T: Storable> {

  // MARK: - Properties

    private let persistence: Persistence
    private let configuration: ServiceConfiguration
    private static var logCategory: String { "\(T.self)" }

    private var _collection: Set<T>?
    private var index: [String: T] = [:]
    private let stateLock = NSLock()

    private var coalesceWorkItem: DispatchWorkItem?
    private let persistQueue = DispatchQueue(label: "com.snappsengineering.snappystorage.persist")

    public var collection: Set<T> {
        loadIfNeeded()
        return _collection!
    }

    public var count: Int {
        loadIfNeeded()
        return index.count
    }

  public var loadState: CollectionLoadState {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard let collection = _collection else { return .notLoaded }
        if loadError != nil { return .failed }
        return collection.isEmpty ? .empty : .loaded(count: collection.count)
    }

    public private(set) var loadError: Error?
    public private(set) var lastError: Error?

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
    }

  // MARK: - Load

    /// Loads and decrypts the backing file on a background queue; safe to call before reads on the main thread.
    public func preload() {
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            loadIfNeeded()
        }
    }

    @discardableResult
    public func load() async -> CollectionLoadState {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                loadIfNeeded()
                continuation.resume(returning: loadState)
            }
        }
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
        mutateLoaded { collection, index in
            collection.upsert(item)
            index[item.id] = item
        }
        schedulePersist()
    }

    open func save(_ items: Set<T>) {
        loadIfNeeded()
        mutateLoaded { collection, index in
            items.forEach {
                collection.upsert($0)
                index[$0.id] = $0
            }
        }
        schedulePersist()
    }

    open func delete(_ item: T) {
        loadIfNeeded()
        mutateLoaded { collection, index in
            collection.remove(item)
            index.removeValue(forKey: item.id)
        }
        schedulePersist()
    }

    open func delete(_ items: Set<T>) {
        loadIfNeeded()
        mutateLoaded { collection, index in
            items.forEach {
                collection.remove($0)
                index.removeValue(forKey: $0.id)
            }
        }
        schedulePersist()
    }

    open func replace(_ items: Set<T>) {
        stateLock.lock()
        if _collection == nil {
            _collection = items
            loadError = nil
            index = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
            stateLock.unlock()
        } else {
            stateLock.unlock()
            loadedCollection = items
            rebuildIndex()
        }
        schedulePersist(allowDespiteLoadFailure: true)
    }

    open func batch(_ changes: (inout Set<T>) -> Void) {
        loadIfNeeded()
        stateLock.lock()
        var updated = _collection!
        stateLock.unlock()
        changes(&updated)
        loadedCollection = updated
        rebuildIndex()
        schedulePersist()
    }

    /// Writes any pending coalesced snapshot immediately.
    public func flush() {
        coalesceWorkItem?.cancel()
        coalesceWorkItem = nil
        stateLock.lock()
        let hasLoadedCollection = _collection != nil
        stateLock.unlock()
        guard hasLoadedCollection else { return }
        performPersist(allowDespiteLoadFailure: false)
    }

  // MARK: - File management

    public func backupFile(suffix: String = "bak") throws -> URL? {
        try persistence.createBackup(suffix: suffix)
    }

    open func setExactlyOne(_ item: T?) {
        batch { items in
            items = item.map { Set([$0]) } ?? []
        }
    }

    open func setDefaultItem(_ item: T) {
        batch { items in
            items.remove(item)
            items.insert(item)
        }
    }

    public func removeFile() throws {
        try persistence.remove()
    }

    public func reload() {
        stateLock.lock()
        let (collection, error) = Self.load(persistence: persistence)
        _collection = collection
        loadError = error
        stateLock.unlock()
        rebuildIndex()
    }

    public func unload() {
        stateLock.lock()
        _collection = nil
        index = [:]
        loadError = nil
        stateLock.unlock()
    }

    open func collectionDidChange() {}

    private var loadedCollection: Set<T> {
        get { _collection! }
        set { _collection = newValue }
    }

    private func mutateLoaded(_ body: (inout Set<T>, inout [String: T]) -> Void) {
        stateLock.lock()
        var collection = _collection!
        var idx = index
        body(&collection, &idx)
        _collection = collection
        index = idx
        stateLock.unlock()
    }

    private func loadIfNeeded() {
        stateLock.lock()
        guard _collection == nil else {
            stateLock.unlock()
            return
        }
        stateLock.unlock()
        let (collection, error) = Self.load(persistence: persistence)
        stateLock.lock()
        if _collection == nil {
            _collection = collection
            loadError = error
            index = Dictionary(uniqueKeysWithValues: collection.map { ($0.id, $0) })
        }
        stateLock.unlock()
    }

    private func rebuildIndex() {
        stateLock.lock()
        index = Dictionary(uniqueKeysWithValues: _collection!.map { ($0.id, $0) })
        stateLock.unlock()
    }

    private func schedulePersist(allowDespiteLoadFailure: Bool = false) {
        let interval = configuration.persistCoalesceInterval
        guard let interval, interval > 0 else {
            performPersist(allowDespiteLoadFailure: allowDespiteLoadFailure)
            return
        }
        coalesceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.performPersist(allowDespiteLoadFailure: allowDespiteLoadFailure)
        }
        coalesceWorkItem = work
        persistQueue.asyncAfter(deadline: .now() + interval, execute: work)
    }

    func persist() {
        schedulePersist()
    }

    private func performPersist(allowDespiteLoadFailure: Bool) {
        stateLock.lock()
        let blocked = loadError != nil && !allowDespiteLoadFailure
        let snapshot = _collection ?? []
        stateLock.unlock()

        guard !blocked else {
            lastError = ServiceError.persistBlockedByLoadFailure
            StorageLog.warning("Skipping persist because the backing file failed to load; on-disk data preserved", category: Self.logCategory)
            collectionDidChange()
            return
        }

        do {
            try persistence.write(Array(snapshot))
            lastError = nil
        } catch {
            lastError = error
            StorageLog.warning("SnappyStorage persist failed: \(error.localizedDescription)", category: Self.logCategory)
        }
        collectionDidChange()
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
