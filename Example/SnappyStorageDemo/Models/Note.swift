import Foundation
import SnappyStorage

struct Note: Storable {
    var id: String = Note.generateHexID()
    var title: String
    var body: String
    var createdAt: Date = .now

    init(title: String, body: String = "") {
        self.title = title
        self.body = body
    }
}
