import Foundation

extension FileManager {

    func url(for directory: FileManager.SearchPathDirectory) throws -> URL {
        let url = try DestinationError.requiredURL(
            urls(for: directory, in: .userDomainMask).last,
            detail: "No URL for directory \(directory)"
        )
        if directory == .applicationSupportDirectory, !fileExists(atPath: url.path) {
            do {
                try createDirectory(at: url, withIntermediateDirectories: true)
            } catch {
                throw StorageError.directoryCreationFailed(url.path)
            }
        }
        return url
    }

    func ubiquityDocumentsURL(folderName: String = "Documents") throws -> URL {
        try DestinationError.requiredURL(
            url(forUbiquityContainerIdentifier: nil)?
                .appendingPathComponent(folderName),
            detail: "iCloud container not available"
        )
    }
}
