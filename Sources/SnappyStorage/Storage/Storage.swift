import Foundation

struct Storage<T> {

    // MARK: - Properties

    let location: Location<T>

    // MARK: - Read and write

    func read() throws -> Data {
        try FileManager.default.data(at: location.defaultFileURL())
    }

    func write(_ data: Data) throws {
        try data.writeAtomic(to: location.defaultFileURL())
    }

    // MARK: - Remove

    func remove() throws {
        try FileManager.default.removeIfExists(at: location.fileURL())
    }
}
