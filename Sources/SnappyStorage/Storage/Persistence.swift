import Foundation

/// One file's worth of encode/encrypt + decode/decrypt, on top of raw byte `Storage`.
///
/// Every service type (`Service`, `ActorService`, `SingleValueService`) owns exactly one
/// `Persistence` — this is where the `Destination` + `File` are resolved into a `Storage`,
/// and where JSON coding and encryption are applied around it.
struct Persistence {

    // MARK: - Properties

    private let storage: Storage
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let encryption: Encryption?

    // MARK: - Lifecycle

    init(
        destination: Destination,
        fileName: String,
        fileExtension: String,
        encoder: JSONEncoder,
        decoder: JSONDecoder,
        encryption: Encryption?
    ) {
        self.storage = Storage(location: Location(
            destination: destination,
            file: File(name: fileName, fileExtension: fileExtension)
        ))
        self.encoder = encoder
        self.decoder = decoder
        self.encryption = encryption
    }

    // MARK: - Read and write

    func read<T: Decodable>(_ type: T.Type) throws -> T {
        let payload = try storage.read()
        let data = try encryption.openedPayload(from: payload)
        return try decoder.decodePayload(type, from: data)
    }

    func write<T: Encodable>(_ value: T) throws {
        let data = try encoder.encodePayload(value)
        try storage.write(try encryption.sealedPayload(from: data))
    }

    // MARK: - Remove

    func remove() throws {
        try storage.remove()
    }
}
