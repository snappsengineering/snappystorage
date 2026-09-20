import Foundation
import SnappyStorage

// MARK: - StoredObject

struct StoredObject: Storable {

    // MARK: - Properties

    var id: String
    var name: String
    var value: Int

    // MARK: - Lifecycle

    init(id: String = StoredObject.generateHexID(), name: String = "test", value: Int = 0) {
        self.id = id
        self.name = name
        self.value = value
    }
}
