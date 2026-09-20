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

    private func makeStorage(fileName: String = "test") -> Storage {
        Storage(
            location: Location(
                destination: .custom(tempDir.path),
                file: File(name: fileName)
            )
        )
    }

    private func makePersistence(fileName: String = "test", encryption: Encryption? = nil) -> Persistence {
        Persistence(
            destination: .custom(tempDir.path),
            fileName: fileName,
            fileExtension: "json",
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            encryption: encryption
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
        XCTAssertThrowsError(try makePersistence().read([StoredObject].self))
    }

    // MARK: - Remove

    func testRemoveDeletesFile() throws {
        let storage = makeStorage(fileName: "removable")
        try storage.write(Data("temp".utf8))
        XCTAssertEqual(try storage.read(), Data("temp".utf8))
        try storage.remove()
        XCTAssertThrowsError(try storage.read())
    }

    // MARK: - Persistence (encode/encrypt round trip)

    func testPersistenceRoundTrip() throws {
        let persistence = makePersistence()
        try persistence.write([StoredObject(name: "a", value: 1)])
        let loaded = try persistence.read([StoredObject].self)
        XCTAssertEqual(loaded.first?.name, "a")
    }

    func testPersistenceEncryptedRoundTrip() throws {
        let enc = Encryption(key: Encryption.generateKey())
        let persistence = makePersistence(encryption: enc)
        try persistence.write([StoredObject(name: "secret", value: 1)])
        XCTAssertEqual(try persistence.read([StoredObject].self).first?.name, "secret")
    }

    func testPersistenceRemove() throws {
        let persistence = makePersistence(fileName: "removable-persistence")
        try persistence.write([StoredObject(name: "a", value: 1)])
        try persistence.remove()
        XCTAssertThrowsError(try persistence.read([StoredObject].self))
    }
}
