import Foundation
import SnappyStorage

// A Storable model that wraps raw image data.
// Service<Photo> can encrypt this on disk using AES-GCM (see EncryptionDemoView).
struct Photo: Storable {
    var id: String = Photo.generateHexID()
    var imageData: Data
    var caption: String
    var savedAt: Date = .now

    init(imageData: Data, caption: String = "") {
        self.imageData = imageData
        self.caption = caption
    }
}
