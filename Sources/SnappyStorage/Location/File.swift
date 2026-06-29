import Foundation

struct File<T> {

    // MARK: - Properties

    var name: String = "\(T.self)"
    var fileExtension: String = "json"

    var fileName: String { "\(name).\(fileExtension)" }
}
