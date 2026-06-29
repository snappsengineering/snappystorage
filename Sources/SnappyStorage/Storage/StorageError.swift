import Foundation

public enum StorageError: LocalizedError {

    // MARK: - Cases

    case fileDoesNotExist
    case directoryCreationFailed(String)
    case ioError(Error)

    // MARK: - Internal

    static var unsupportedLayout: NSError {
        NSError(domain: "SnappyStorage", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Collection layout is not supported yet"
        ])
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .fileDoesNotExist: return "Storage file does not exist"
        case .directoryCreationFailed(let p): return "Failed to create directory: \(p)"
        case .ioError(let e): return "I/O error: \(e.localizedDescription)"
        }
    }
}
