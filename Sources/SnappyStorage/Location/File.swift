import Foundation

struct File {

    // MARK: - Properties

    var name: String
    var fileExtension: String = "json"

    var fileName: String { "\(name).\(fileExtension)" }
}
