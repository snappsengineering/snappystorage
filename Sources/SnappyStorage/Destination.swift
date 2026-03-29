import Foundation

public enum Destination {
    case local(FileManager.SearchPathDirectory)
    case cloud
    case custom(String)

    static var documentsFolderName: String { "Documents" }

    public func makeURL(
        with fileManager: FileManager,
        fileName: String,
        fileExtension: String
    ) throws -> URL {
        let base: URL
        switch self {
        case .local(let directory):
            guard let url = fileManager.urls(for: directory, in: .userDomainMask).last else {
                throw DestinationError.urlNotFound("No URL for directory \(directory)")
            }
            base = url
        case .cloud:
            guard let url = fileManager.url(forUbiquityContainerIdentifier: nil)?
                .appendingPathComponent(Destination.documentsFolderName) else {
                throw DestinationError.urlNotFound("iCloud container not available")
            }
            base = url
        case .custom(let path):
            base = URL(fileURLWithPath: path, isDirectory: true)
        }
        return base.appendingPathComponent("\(fileName).\(fileExtension)")
    }

    public enum DestinationError: LocalizedError {
        case urlNotFound(String)

        public var errorDescription: String? {
            switch self {
            case .urlNotFound(let detail): return "Destination URL not found: \(detail)"
            }
        }
    }
}
