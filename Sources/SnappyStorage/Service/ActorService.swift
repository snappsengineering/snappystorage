import Foundation

public actor ActorService<T: Storable & Sendable> {

    // MARK: - Properties

    private let persistence: Persistence
    private var collection: Set<T>
    private let continuation: AsyncStream<Set<T>>.Continuation

    public let updates: AsyncStream<Set<T>>

    // MARK: - Lifecycle

    public init(
        destination: Destination = .local(.documentDirectory),
        fileName: String? = nil,
        fileExtension: String = "json",
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = JSONDecoder(),
        encryption: Encryption? = nil
    ) throws {
        let persistence = Persistence(
            destination: destination,
            fileName: fileName ?? "\(T.self)",
            fileExtension: fileExtension,
            encoder: jsonEncoder,
            decoder: jsonDecoder,
            encryption: encryption
        )
        self.persistence = persistence
        do {
            self.collection = Set(try persistence.read([T].self))
        } catch StorageError.fileDoesNotExist {
            self.collection = []
        }
        let (stream, continuation) = AsyncStream<Set<T>>.makeStream(bufferingPolicy: .bufferingNewest(1))
        self.updates = stream
        self.continuation = continuation
        continuation.yield(collection)
    }

    deinit {
        continuation.finish()
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
        try persistence.remove()
    }

    // MARK: - Private

    private func persist() {
        try? persistence.write(Array(collection))
        continuation.yield(collection)
    }
}
