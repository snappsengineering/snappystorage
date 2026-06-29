import Foundation
import Combine

open class PublishedSingleValueService<T: Codable>: SingleValueService<T> {

    // MARK: - Properties

    @Published public var published: T?

    // MARK: - Lifecycle

    public override init(
        destination: Destination = .local(.documentDirectory),
        fileName: String,
        fileExtension: String = "json",
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = JSONDecoder(),
        encryption: Encryption? = nil
    ) {
        super.init(
            destination: destination,
            fileName: fileName,
            fileExtension: fileExtension,
            jsonEncoder: jsonEncoder,
            jsonDecoder: jsonDecoder,
            encryption: encryption
        )
        published = fetch()
    }

    // MARK: - Write

    public func saveAndPublish(_ value: T) throws {
        try save(value)
        published = value
    }

    public func removeAndPublish() throws {
        try remove()
        published = nil
    }
}
