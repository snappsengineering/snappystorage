import XCTest
@testable import SnappyStorage

final class StorageTests: XCTestCase {

    // MARK: - Properties

    private var tempDir: URL!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnappyStorageTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Helpers

    private struct TestFile {}

    private func makeStorage(fileName: String = "test") -> Storage<TestFile> {
        Storage(
            location: Location(
                destination: .custom(tempDir.path),
                file: File<TestFile>(name: fileName)
            )
        )
    }

    // MARK: - Read and write

    func testWriteAndRead() throws {
        let storage = makeStorage()
        let data = Data("hello".utf8)
        try storage.write(data)
        XCTAssertEqual(try storage.read(), data)
    }

    func testReadThrowsWhenNoFile() throws {
        let storage = makeStorage(fileName: "missing")
        XCTAssertThrowsError(try storage.read()) { error in
            guard case StorageError.fileDoesNotExist = error else {
                return XCTFail("Expected fileDoesNotExist, got \(error)")
            }
        }
    }

    func testCorruptDataThrowsOnDecode() throws {
        let storage = makeStorage()
        try storage.write(Data("{ not json".utf8))
        XCTAssertThrowsError(
            try Payload.fetchItems(
                StoredObject.self,
                storage: storage,
                jsonDecoder: JSONDecoder(),
                encryption: nil
            )
        )
    }

    // MARK: - Remove

    func testRemoveDeletesFile() throws {
        let storage = makeStorage(fileName: "removable")
        try storage.write(Data("temp".utf8))
        XCTAssertEqual(try storage.read(), Data("temp".utf8))
        try storage.remove()
        XCTAssertThrowsError(try storage.read())
    }
}
