import Foundation

/// Actor-based service for use with Swift concurrency.
/// Thread-safe collection management with AsyncStream updates.
public actor ActorService<T: Storable & Sendable> {

    private let storage: Storage
    private var collection: Set<T>
    private let continuation: AsyncStream<Set<T>>.Continuation
    private let _stream: AsyncStream<Set<T>>

    public var updates: AsyncStream<Set<T>> { _stream }

    public init(
        destination: Destination = .local(.documentDirectory),
        fileName: String? = nil,
        fileExtension: String = "json",
        encryption: Encryption? = nil
    ) throws {
        let name = fileName ?? "\(T.self)"
        self.storage = try Storage(
            destination: destination,
            fileName: name,
            fileExtension: fileExtension,
            encryption: encryption
        )
        self.collection = storage.fetchCollectionOrEmpty()
        let (stream, continuation) = AsyncStream<Set<T>>.makeStream(bufferingPolicy: .bufferingNewest(1))
        self._stream = stream
        self.continuation = continuation
        continuation.yield(collection)
    }

    public func fetchAll() -> Set<T> {
        collection
    }

    public func fetch(id: String) -> T? {
        collection.first { $0.id == id }
    }

    public func save(_ item: T) {
        collection.update(with: item)
        persist()
    }

    public func save(_ items: Set<T>) {
        items.forEach { collection.update(with: $0) }
        persist()
    }

    public func delete(_ item: T) {
        collection.remove(item)
        persist()
    }

    public func removeFile() throws {
        try storage.remove()
    }

    private func persist() {
        try? storage.store(collection: collection)
        continuation.yield(collection)
    }
}
