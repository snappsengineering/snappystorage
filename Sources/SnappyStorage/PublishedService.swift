import Foundation
import Combine

/// Combine-reactive wrapper around Service. Publishes collection changes via @Published.
/// Conforms to ObservableObject so subclasses can be used as @StateObject / @ObservedObject.
open class PublishedService<T: Storable>: Service<T>, ObservableObject {

    @Published public var published: Set<T> = []

    public override init(
        destination: Destination = .local(.documentDirectory),
        fileName: String? = nil,
        fileExtension: String = "json",
        encryption: Encryption? = nil
    ) {
        super.init(
            destination: destination,
            fileName: fileName,
            fileExtension: fileExtension,
            encryption: encryption
        )
        published = collection
    }

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
