import Foundation

/// Manages an in-memory Set<T> backed by file storage. Synchronous, subclassable.
open class Service<T: Storable> {

    private let storage: Storage

    public private(set) var collection: Set<T>

    public init(
        destination: Destination = .local(.documentDirectory),
        fileName: String? = nil,
        fileExtension: String = "json",
        encryption: Encryption? = nil
    ) {
        let name = fileName ?? "\(T.self)"
        // Fatal here mirrors v1.0.0 behavior — destination must be valid at init time.
        // swiftlint:disable:next force_try
        self.storage = try! Storage(
            destination: destination,
            fileName: name,
            fileExtension: fileExtension,
            encryption: encryption
        )
        self.collection = storage.fetchCollectionOrEmpty()
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
        collection.update(with: item)
        persist()
    }

    open func save(_ items: Set<T>) {
        items.forEach { collection.update(with: $0) }
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
        collection = storage.fetchCollectionOrEmpty()
    }

    // MARK: - Internal

    func persist() {
        try? storage.store(collection: collection)
    }
}
