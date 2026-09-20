import Foundation
import SnappyStorage

struct Note: Storable {

    // MARK: - Properties

    var id: String = Note.generateHexID()
    var title: String
    var body: String
    var createdAt: Date = .now

    // MARK: - Lifecycle

    init(title: String, body: String = "") {
        self.title = title
        self.body = body
    }
}
