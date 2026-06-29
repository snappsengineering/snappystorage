import Foundation

open class Service<T: Storable> {

    // MARK: - Properties

    private let storage: Storage<T>
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    private let encryption: Encryption?

    public private(set) var collection: Set<T>

    // MARK: - Lifecycle

    public init(
        destination: Destination = .local(.documentDirectory),
        fileName: String? = nil,
        fileExtension: String = "json",
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = JSONDecoder(),
        encryption: Encryption? = nil
    ) {
        self.storage = ServiceBacking.makeStorage(
            destination: destination,
            fileName: fileName,
            fileExtension: fileExtension
        )
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
        self.encryption = encryption
        self.collection = Self.initialCollection(
            storage: storage,
            jsonDecoder: jsonDecoder,
            encryption: encryption
        )
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
        try storage.remove()
    }

    public func reload() {
        do {
            collection = try Payload.loadCollection(
                storage: storage,
                jsonDecoder: jsonDecoder,
                encryption: encryption
            )
        } catch StorageError.fileDoesNotExist {
            collection = []
        } catch {
            // leave collection unchanged on decode / decrypt failure
        }
    }

    // MARK: - Internal

    func persist() {
        try? Payload.storeItems(
            Array(collection),
            storage: storage,
            jsonEncoder: jsonEncoder,
            encryption: encryption
        )
    }

    private static func initialCollection(
        storage: Storage<T>,
        jsonDecoder: JSONDecoder,
        encryption: Encryption?
    ) -> Set<T> {
        do {
            return try Payload.loadCollection(
                storage: storage,
                jsonDecoder: jsonDecoder,
                encryption: encryption
            )
        } catch StorageError.fileDoesNotExist {
            return []
        } catch {
            fatalError("SnappyStorage failed to load collection: \(error)")
        }
    }
}
