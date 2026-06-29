import Foundation

open class SingleValueService<T: Codable> {

    // MARK: - Properties

    private let storage: Storage<T>
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    private let encryption: Encryption?

    // MARK: - Lifecycle

    public init(
        destination: Destination = .local(.documentDirectory),
        fileName: String,
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
    }

    // MARK: - Read

    public func fetch() -> T? {
        try? Payload.read(T.self, storage: storage, jsonDecoder: jsonDecoder, encryption: encryption)
    }

    // MARK: - Write

    public func save(_ value: T) throws {
        try Payload.write(value, storage: storage, jsonEncoder: jsonEncoder, encryption: encryption)
    }

    public func remove() throws {
        try storage.remove()
    }
}
