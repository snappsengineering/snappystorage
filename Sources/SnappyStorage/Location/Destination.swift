import Foundation

public enum Destination: Sendable {
    case local(FileManager.SearchPathDirectory)
    case iCloud
    case custom(String)
}

// MARK: - Deprecated aliases

extension Destination {

    @available(*, deprecated, renamed: "iCloud")
    public static var cloud: Destination { .iCloud }
}

// MARK: - URL resolution

extension Destination {

    func url(for file: File) throws -> URL {
        try folderURL().appendingPathComponent(file.fileName)
    }

    private func folderURL() throws -> URL {
        let fileManager = FileManager.default
        switch self {
        case .local(let directory):
            return try fileManager.url(for: directory)
        case .iCloud:
            return try fileManager.ubiquityDocumentsURL()
        case .custom(let path):
            return URL(fileURLWithPath: path, isDirectory: true)
        }
    }
}
