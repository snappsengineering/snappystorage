import Foundation

public actor ActorService<T: Storable & Sendable> {

    // MARK: - Properties

    private let storage: Storage<T>
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    private let encryption: Encryption?
    private var collection: Set<T>
    private let continuation: AsyncStream<Set<T>>.Continuation
    private let _stream: AsyncStream<Set<T>>

    public var updates: AsyncStream<Set<T>> { _stream }

    // MARK: - Lifecycle

    public init(
        destination: Destination = .local(.documentDirectory),
        fileName: String? = nil,
        fileExtension: String = "json",
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = JSONDecoder(),
        encryption: Encryption? = nil
    ) throws {
        self.storage = ServiceBacking.makeStorage(
            destination: destination,
            fileName: fileName,
            fileExtension: fileExtension
        )
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
        self.encryption = encryption
        do {
            self.collection = try Payload.loadCollection(
                storage: storage,
                jsonDecoder: jsonDecoder,
                encryption: encryption
            )
        } catch StorageError.fileDoesNotExist {
            self.collection = []
        }
        let (stream, continuation) = AsyncStream<Set<T>>.makeStream(bufferingPolicy: .bufferingNewest(1))
        self._stream = stream
        self.continuation = continuation
        continuation.yield(collection)
    }

    // MARK: - Read

    public func fetchAll() -> Set<T> {
        collection
    }

    public func fetch(id: String) -> T? {
        collection.first { $0.id == id }
    }

    // MARK: - Write

    public func save(_ item: T) {
        collection.upsert(item)
        persist()
    }

    public func save(_ items: Set<T>) {
        items.forEach { collection.upsert($0) }
        persist()
    }

    public func delete(_ item: T) {
        collection.remove(item)
        persist()
    }

    // MARK: - File management

    public func removeFile() throws {
        try storage.remove()
    }

    // MARK: - Private

    private func persist() {
        try? Payload.storeItems(
            Array(collection),
            storage: storage,
            jsonEncoder: jsonEncoder,
            encryption: encryption
        )
        continuation.yield(collection)
    }
}
