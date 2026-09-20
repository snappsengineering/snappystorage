import Foundation

open class SingleValueService<T: Codable> {

    // MARK: - Properties

    private let persistence: Persistence

    // MARK: - Lifecycle

    public init(
        destination: Destination = .local(.documentDirectory),
        fileName: String,
        fileExtension: String = "json",
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = JSONDecoder(),
        encryption: Encryption? = nil
    ) {
        self.persistence = Persistence(
            destination: destination,
            fileName: fileName,
            fileExtension: fileExtension,
            encoder: jsonEncoder,
            decoder: jsonDecoder,
            encryption: encryption
        )
    }

    // MARK: - Read

    /// Throwing read — surfaces corrupt data or decrypt failure instead of silently
    /// returning `nil`. Prefer this over `fetch()` when overwriting with a default
    /// value on `nil` would destroy an undecryptable-but-recoverable file.
    public func load() throws -> T? {
        do {
            return try persistence.read(T.self)
        } catch StorageError.fileDoesNotExist {
            return nil
        }
    }

    public func fetch() -> T? {
        try? load()
    }

    // MARK: - Write

    public func save(_ value: T) throws {
        try persistence.write(value)
    }

    public func remove() throws {
        try persistence.remove()
    }
}
