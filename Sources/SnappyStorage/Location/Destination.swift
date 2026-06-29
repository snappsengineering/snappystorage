import Foundation

public enum Destination {
    case local(FileManager.SearchPathDirectory)
    case cloud
    case custom(String)
}

// MARK: - URL resolution

extension Destination {

    func url<T>(for file: File<T>) throws -> URL {
        try folderURL().appendingPathComponent(file.fileName)
    }

    private func folderURL() throws -> URL {
        let fileManager = FileManager.default
        switch self {
        case .local(let directory):
            return try fileManager.url(for: directory)
        case .cloud:
            return try fileManager.ubiquityDocumentsURL()
        case .custom(let path):
            return URL(fileURLWithPath: path, isDirectory: true)
        }
    }
}
