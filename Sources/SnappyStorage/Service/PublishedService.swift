#if canImport(Combine)
import Combine
import Foundation

open class PublishedService<T: Storable>: Service<T>, ObservableObject {

    @Published public var published: Set<T> = []

    public override init(
        destination: Destination = .local(.documentDirectory),
        fileName: String? = nil,
        fileExtension: String = "json",
        jsonEncoder: JSONEncoder = JSONEncoder(),
        jsonDecoder: JSONDecoder = JSONDecoder(),
        encryption: Encryption? = nil,
        configuration: ServiceConfiguration = ServiceConfiguration()
    ) {
        super.init(
            destination: destination,
            fileName: fileName,
            fileExtension: fileExtension,
            jsonEncoder: jsonEncoder,
            jsonDecoder: jsonDecoder,
            encryption: encryption,
            configuration: configuration
        )
        published = collection
    }

    open override func collectionDidChange() {
        published = collection
    }
}
#endif
