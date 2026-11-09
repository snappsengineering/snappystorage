import Foundation

public enum SingleValueLoadState: Sendable, Equatable {
    case notRead
    case present
    case missing
    case failed
}

open class SingleValueService<T: Codable> {

    private let persistence: Persistence
    public private(set) var lastError: Error?
    public private(set) var lastLoadState: SingleValueLoadState = .notRead

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

    public func load() throws -> T? {
        do {
            let value = try persistence.read(T.self)
            lastLoadState = .present
            lastError = nil
            return value
        } catch StorageError.fileDoesNotExist {
            lastLoadState = .missing
            lastError = nil
            return nil
        } catch {
            lastLoadState = .failed
            lastError = error
            StorageLog.warning("SingleValueService load failed: \(error.localizedDescription)", category: "SingleValue")
            throw error
        }
    }

    public func fetch() -> T? {
        try? load()
    }

    public func save(_ value: T) throws {
        try persistence.write(value)
        lastError = nil
        lastLoadState = .present
    }

    public func remove() throws {
        try persistence.remove()
        lastError = nil
        lastLoadState = .missing
    }

    public func backupFile(suffix: String = "bak") throws -> URL? {
        try persistence.createBackup(suffix: suffix)
    }
}
