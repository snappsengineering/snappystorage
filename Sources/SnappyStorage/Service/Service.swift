import Foundation
import os

open class Service<T: Storable> {

    // MARK: - Properties

    private let persistence: Persistence
    private static var logger: Logger { Logger(subsystem: "com.snappsengineering.snappystorage", category: "\(T.self)") }

    public private(set) var collection: Set<T>

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
        let (collection, error) = Self.load(persistence: persistence)
        self.collection = collection
        self.loadError = error
    }

    // MARK: - Read

    public func fetchAll() -> Set<T> {
        collection
    }

    public func fetch(id: String) -> T? {
        collection.first { $0.id == id }
    }

    // MARK: - Write

    open func save(_ item: T) {
        collection.upsert(item)
        persist()
    }

    open func save(_ items: Set<T>) {
        items.forEach { collection.upsert($0) }
        persist()
    }

    open func delete(_ item: T) {
        collection.remove(item)
        persist()
    }

    // MARK: - File management

    public func removeFile() throws {
        try persistence.remove()
    }

    public func reload() {
        let (collection, error) = Self.load(persistence: persistence)
        self.collection = collection
        self.loadError = error
    }

    // MARK: - Change hook

    /// Called once after every successful `save`/`delete`. Override to react to changes —
    /// `PublishedService` mirrors `collection` into `@Published published` here.
    open func collectionDidChange() {}

    // MARK: - Internal

    func persist() {
        do {
            try persistence.write(Array(collection))
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
