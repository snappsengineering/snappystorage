import Foundation

/// Actor-based service for use with Swift concurrency.
/// Thread-safe collection management with AsyncStream updates.
public actor ActorService<T: Storable & Sendable> {

    private let storage: Storage
    private var collection: [T]
    private let continuation: AsyncStream<[T]>.Continuation
    private let _stream: AsyncStream<[T]>

    public var updates: AsyncStream<[T]> { _stream }

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
        let (stream, continuation) = AsyncStream<[T]>.makeStream(bufferingPolicy: .bufferingNewest(1))
        self._stream = stream
        self.continuation = continuation
        continuation.yield(collection)
    }

    public func fetchAll() -> [T] {
        collection
    }

    public func fetch(id: String) -> T? {
        collection.first { $0.id == id }
    }

    public func save(_ item: T) {
        if let index = collection.firstIndex(where: { $0.id == item.id }) {
            collection[index] = item
        } else {
            collection.append(item)
        }
        persist()
    }

    public func save(_ items: [T]) {
        for item in items {
            if let index = collection.firstIndex(where: { $0.id == item.id }) {
                collection[index] = item
            } else {
                collection.append(item)
            }
        }
        persist()
    }

    public func replace(_ items: [T]) {
        collection = items
        persist()
    }

    public func delete(_ item: T) {
        collection.removeAll { $0.id == item.id }
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
