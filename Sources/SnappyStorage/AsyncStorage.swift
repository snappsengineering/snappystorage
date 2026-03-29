import Foundation

/// Async wrappers around Storage for use with Swift concurrency.
public struct AsyncStorage {

    private let storage: Storage

    public init(
        destination: Destination,
        fileName: String,
        fileExtension: String = "json",
        encryption: Encryption? = nil
    ) throws {
        self.storage = try Storage(
            destination: destination,
            fileName: fileName,
            fileExtension: fileExtension,
            encryption: encryption
        )
    }

    // MARK: - Collection

    public func store<T: Storable>(collection: Set<T>) async throws {
        try storage.store(collection: collection)
    }

    public func fetchCollection<T: Storable>() async throws -> Set<T> {
        try storage.fetchCollection()
    }

    // MARK: - Single value

    public func store<T: Codable>(_ value: T) async throws {
        try storage.store(value)
    }

    public func fetchValue<T: Codable>() async throws -> T {
        try storage.fetchValue()
    }

    // MARK: - Raw Data

    public func storeData(_ data: Data) async throws {
        try storage.storeData(data)
    }

    public func fetchData() async throws -> Data {
        try storage.fetchData()
    }

    // MARK: - Remove

    public func remove() async throws {
        try storage.remove()
    }
}
