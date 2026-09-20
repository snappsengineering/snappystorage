import Foundation

extension FileManager {

    func url(for directory: FileManager.SearchPathDirectory) throws -> URL {
        try DestinationError.requiredURL(
            urls(for: directory, in: .userDomainMask).last,
            detail: "No URL for directory \(directory)"
        )
    }

    func ubiquityDocumentsURL(folderName: String = "Documents") throws -> URL {
        try DestinationError.requiredURL(
            url(forUbiquityContainerIdentifier: nil)?
                .appendingPathComponent(folderName),
            detail: "iCloud container not available"
        )
    }
}
