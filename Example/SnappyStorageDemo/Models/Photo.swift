import Foundation
import SnappyStorage

struct Photo: Storable {

    // MARK: - Properties

    var id: String = Photo.generateHexID()
    var imageData: Data
    var caption: String
    var savedAt: Date = .now

    // MARK: - Lifecycle

    init(imageData: Data, caption: String = "") {
        self.imageData = imageData
        self.caption = caption
    }
}
