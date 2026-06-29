import Foundation

enum ServiceBacking {

    static func makeFile<T>(fileName: String?, fileExtension: String) -> File<T> {
        var file = File<T>()
        if let fileName { file.name = fileName }
        if fileExtension != "json" { file.fileExtension = fileExtension }
        return file
    }

    static func makeLocation<T>(
        destination: Destination,
        fileName: String?,
        fileExtension: String
    ) -> Location<T> {
        Location(
            destination: destination,
            file: makeFile(fileName: fileName, fileExtension: fileExtension)
        )
    }

    static func makeStorage<T>(
        destination: Destination = .local(.documentDirectory),
        fileName: String?,
        fileExtension: String = "json"
    ) -> Storage<T> {
        Storage(location: makeLocation(
            destination: destination,
            fileName: fileName,
            fileExtension: fileExtension
        ))
    }
}
