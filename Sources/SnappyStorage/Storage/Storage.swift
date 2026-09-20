import Foundation

struct Storage {

    // MARK: - Properties

    let location: Location

    // MARK: - Read and write

    func read() throws -> Data {
        try FileManager.default.data(at: location.fileURL())
    }

    func write(_ data: Data) throws {
        try data.writeAtomic(to: location.fileURL())
    }

    // MARK: - Remove

    func remove() throws {
        try FileManager.default.removeIfExists(at: location.fileURL())
    }
}
