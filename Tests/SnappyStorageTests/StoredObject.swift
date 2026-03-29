import Foundation
import SnappyStorage

struct StoredObject: Storable {
    var id: String
    var name: String
    var value: Int

    init(id: String = StoredObject.generateHexID(), name: String = "test", value: Int = 0) {
        self.id = id
        self.name = name
        self.value = value
    }
}
