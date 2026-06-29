import Foundation

struct Location<T> {

    // MARK: - Properties

    var destination: Destination
    var file: File<T>
    var layout: Layout = .default
}

extension Location {

    func fileURL() throws -> URL {
        try destination.url(for: file)
    }

    func defaultFileURL() throws -> URL {
        guard layout.usesDefaultFile else {
            throw StorageError.ioError(StorageError.unsupportedLayout)
        }
        return try fileURL()
    }
}
