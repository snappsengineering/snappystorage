import Foundation
import Combine

/// Combine-reactive wrapper around SingleValueService. Publishes value changes via @Published.
open class PublishedSingleValueService<T: Codable>: SingleValueService<T> {

    @Published public var published: T?

    public override init(
        destination: Destination = .local(.documentDirectory),
        fileName: String,
        fileExtension: String = "json",
        encryption: Encryption? = nil
    ) {
        super.init(
            destination: destination,
            fileName: fileName,
            fileExtension: fileExtension,
            encryption: encryption
        )
        published = fetch()
    }

    public func saveAndPublish(_ value: T) throws {
        try save(value)
        published = value
    }

    public func removeAndPublish() throws {
        try remove()
        published = nil
    }
}
