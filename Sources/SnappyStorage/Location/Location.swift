import Foundation

struct Location {

    // MARK: - Properties

    var destination: Destination
    var file: File
}

extension Location {

    func fileURL() throws -> URL {
        try destination.url(for: file)
    }
}
