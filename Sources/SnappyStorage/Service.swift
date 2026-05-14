import Foundation

/// Manages an in-memory [T] backed by file storage. Synchronous, subclassable.
/// Items are unique by `id` — saving an item with an existing ID replaces it in place.
open class Service<T: Storable> {

    private let storage: Storage

    public private(set) var collection: [T]

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

    public func fetchAll() -> [T] {
        collection
    }

    public func fetch(id: String) -> T? {
        collection.first { $0.id == id }
    }

    // MARK: - Write

    open func save(_ item: T) {
        if let index = collection.firstIndex(where: { $0.id == item.id }) {
            collection[index] = item
        } else {
            collection.append(item)
        }
        persist()
    }

    open func save(_ items: [T]) {
        for item in items {
            if let index = collection.firstIndex(where: { $0.id == item.id }) {
                collection[index] = item
            } else {
                collection.append(item)
            }
        }
        persist()
    }

    open func replace(_ items: [T]) {
        collection = items
        persist()
    }

    open func delete(_ item: T) {
        collection.removeAll { $0.id == item.id }
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
