import Foundation

public enum StorageError: LocalizedError {
    case fileDoesNotExist
    case directoryCreationFailed(String)
    case encodingFailed(Error)
    case decodingFailed(Error)
    case encryptionFailed(Encryption.EncryptionError)
    case decryptionFailed(Encryption.EncryptionError)
    case ioError(Error)

    public var errorDescription: String? {
        switch self {
        case .fileDoesNotExist: return "Storage file does not exist"
        case .directoryCreationFailed(let p): return "Failed to create directory: \(p)"
        case .encodingFailed(let e): return "Encoding failed: \(e.localizedDescription)"
        case .decodingFailed(let e): return "Decoding failed: \(e.localizedDescription)"
        case .encryptionFailed(let e): return "Encryption failed: \(e.localizedDescription)"
        case .decryptionFailed(let e): return "Decryption failed: \(e.localizedDescription)"
        case .ioError(let e): return "I/O error: \(e.localizedDescription)"
        }
    }
}

/// Low-level file-backed storage. All operations are synchronous.
public class Storage {

    private let storageURL: URL
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()
    private let fileManager: FileManager
    private let encryption: Encryption?

    public var fileExists: Bool {
        fileManager.fileExists(atPath: storageURL.path)
    }

    public init(
        destination: Destination,
        fileName: String,
        fileExtension: String = "json",
        encryption: Encryption? = nil,
        fileManager: FileManager = .default
    ) throws {
        self.fileManager = fileManager
        self.encryption = encryption
        self.storageURL = try destination.makeURL(
            with: fileManager,
            fileName: fileName,
            fileExtension: fileExtension
        )
    }

    // MARK: - Collection (Set<T: Storable>)

    public func store<T: Storable>(collection: Set<T>) throws {
        let data = try encode(collection)
        try writeData(data)
    }

    public func fetchCollection<T: Storable>() throws -> Set<T> {
        let data = try readData()
        return try decode(data)
    }

    public func fetchCollectionOrEmpty<T: Storable>() -> Set<T> {
        (try? fetchCollection()) ?? []
    }

    // MARK: - Single value (any Codable)

    public func store<T: Codable>(_ value: T) throws {
        let data = try encode(value)
        try writeData(data)
    }

    public func fetchValue<T: Codable>() throws -> T {
        let data = try readData()
        return try decode(data)
    }

    // MARK: - Raw Data

    public func storeData(_ data: Data) throws {
        try writeData(data)
    }

    public func fetchData() throws -> Data {
        try readData()
    }

    // MARK: - Remove

    public func remove() throws {
        guard fileExists else { return }
        do {
            try fileManager.removeItem(at: storageURL)
        } catch {
            throw StorageError.ioError(error)
        }
    }

    // MARK: - Metadata

    public var lastUpdated: Date? {
        try? fileManager.attributesOfItem(atPath: storageURL.path)[.modificationDate] as? Date
    }

    // MARK: - Private

    private func ensureDirectoryExists() throws {
        let folder = storageURL.deletingLastPathComponent()
        guard !fileManager.fileExists(atPath: folder.path) else { return }
        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            throw StorageError.directoryCreationFailed(folder.path)
        }
    }

    private func encode<T: Encodable>(_ value: T) throws -> Data {
        do {
            return try jsonEncoder.encode(value)
        } catch {
            throw StorageError.encodingFailed(error)
        }
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw StorageError.decodingFailed(error)
        }
    }

    private func writeData(_ raw: Data) throws {
        try ensureDirectoryExists()
        let toWrite: Data
        if let encryption = encryption {
            do { toWrite = try encryption.encrypt(raw) }
            catch let e as Encryption.EncryptionError { throw StorageError.encryptionFailed(e) }
            catch { throw StorageError.encryptionFailed(.encryptionFailed(error)) }
        } else {
            toWrite = raw
        }
        do {
            try toWrite.write(to: storageURL, options: .atomic)
        } catch {
            throw StorageError.ioError(error)
        }
    }

    private func readData() throws -> Data {
        guard fileExists else { throw StorageError.fileDoesNotExist }
        let raw: Data
        do {
            raw = try Data(contentsOf: storageURL)
        } catch {
            throw StorageError.ioError(error)
        }
        if let encryption = encryption {
            do { return try encryption.decrypt(raw) }
            catch let e as Encryption.EncryptionError { throw StorageError.decryptionFailed(e) }
            catch { throw StorageError.decryptionFailed(.decryptionFailed(error)) }
        }
        return raw
    }
}
