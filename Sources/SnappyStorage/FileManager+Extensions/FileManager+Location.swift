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

    static func defaultUbiquityContainerURL(for identifier: String?) -> URL? {
        #if os(iOS) || os(macOS) || os(tvOS) || os(watchOS) || os(visionOS)
        return FileManager.default.url(forUbiquityContainerIdentifier: identifier)
        #else
        return nil
        #endif
    }

    func ubiquityDocumentsURL(
        folderName: String = "Documents",
        containerURLProvider: (String?) -> URL? = FileManager.defaultUbiquityContainerURL
    ) throws -> URL {
        try DestinationError.requiredURL(
            containerURLProvider(nil)?.appendingPathComponent(folderName),
            detail: "iCloud container not available"
        )
    }
}
