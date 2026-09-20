import Foundation

/// Raw byte storage for blobs that don't fit the `Storable` JSON model — PDFs, images, exports.
/// Use `Service<T>` for anything `Storable`; reach for `BlobService` only for opaque `Data`.
open class BlobService {

    // MARK: - Properties

    private let storage: Storage

    // MARK: - Lifecycle

    public init(destination: Destination, fileName: String, fileExtension: String) {
        self.storage = Storage(location: Location(
            destination: destination,
            file: File(name: fileName, fileExtension: fileExtension)
        ))
    }

    // MARK: - Read and write

    public func fetchData() throws -> Data {
        try storage.read()
    }

    public func storeData(_ data: Data) throws {
        try storage.write(data)
    }

    // MARK: - Remove

    public func remove() throws {
        try storage.remove()
    }
}
