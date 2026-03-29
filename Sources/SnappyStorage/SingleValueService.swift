import Foundation

/// Manages a single Codable value backed by file storage.
/// Replaces UserDefaults for structured app state (e.g. app settings, feature flags).
open class SingleValueService<T: Codable> {

    private let storage: Storage

    public init(
        destination: Destination = .local(.documentDirectory),
        fileName: String,
        fileExtension: String = "json",
        encryption: Encryption? = nil
    ) {
        // swiftlint:disable:next force_try
        self.storage = try! Storage(
            destination: destination,
            fileName: fileName,
            fileExtension: fileExtension,
            encryption: encryption
        )
    }

    public func save(_ value: T) throws {
        try storage.store(value)
    }

    public func fetch() -> T? {
        try? storage.fetchValue()
    }

    public func remove() throws {
        try storage.remove()
    }

    public var exists: Bool {
        storage.fileExists
    }
}
