import Foundation

extension FileManager {

    func exists(at url: URL) -> Bool {
        fileExists(atPath: url.path)
    }

    func ensureDirectory(at fileURL: URL) throws {
        let folder = fileURL.deletingLastPathComponent()
        guard !exists(at: folder) else { return }
        do {
            try createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            throw StorageError.directoryCreationFailed(folder.path)
        }
    }

    func removeIfExists(at url: URL) throws {
        guard exists(at: url) else { return }
        do {
            try removeItem(at: url)
        } catch {
            throw StorageError.ioError(error)
        }
    }

    func modificationDate(at url: URL) -> Date? {
        guard exists(at: url) else { return nil }
        return try? attributesOfItem(atPath: url.path)[.modificationDate] as? Date
    }

    func data(at url: URL) throws -> Data {
        guard exists(at: url) else { throw StorageError.fileDoesNotExist }
        do {
            return try Data(contentsOf: url)
        } catch {
            throw StorageError.ioError(error)
        }
    }
}

extension Data {

    func writeAtomic(to url: URL) throws {
        try FileManager.default.ensureDirectory(at: url)
        do {
            try write(to: url, options: .atomic)
        } catch {
            throw StorageError.ioError(error)
        }
    }
}
