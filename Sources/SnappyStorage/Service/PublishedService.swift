import Foundation
import Combine

open class PublishedService<T: Storable>: Service<T>, ObservableObject {

    // MARK: - Properties

    @Published public var published: Set<T> = []

    // MARK: - Lifecycle

    public override init(
        destination: Destination = .local(.documentDirectory),
        fileName: String? = nil,
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
        published = collection
    }

    // MARK: - Write

    open override func save(_ item: T) {
        super.save(item)
        published = collection
    }

    open override func save(_ items: Set<T>) {
        super.save(items)
        published = collection
    }

    open override func delete(_ item: T) {
        super.delete(item)
        published = collection
    }
}
