import XCTest
@testable import SnappyStorage

final class StorageTests: XCTestCase {

    private var tempDir: URL!

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

    private func makeStorage(fileName: String = "test", encryption: Encryption? = nil) throws -> Storage {
        try Storage(
            destination: .custom(tempDir.path),
            fileName: fileName,
            encryption: encryption
        )
    }

    // MARK: - Collection

    func testStoreAndFetchCollection() throws {
        let storage = try makeStorage()
        let items: Set<StoredObject> = [
            StoredObject(name: "a", value: 1),
            StoredObject(name: "b", value: 2)
        ]
        try storage.store(collection: items)
        let fetched: Set<StoredObject> = try storage.fetchCollection()
        XCTAssertEqual(fetched.count, 2)
    }

    func testFetchCollectionOrEmptyWhenNoFile() throws {
        let storage = try makeStorage(fileName: "nonexistent")
        let result: Set<StoredObject> = storage.fetchCollectionOrEmpty()
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Single value

    func testStoreAndFetchSingleValue() throws {
        let storage = try makeStorage(fileName: "single")
        try storage.store("hello")
        let fetched: String = try storage.fetchValue()
        XCTAssertEqual(fetched, "hello")
    }

    func testStoreAndFetchCodableStruct() throws {
        struct Info: Codable, Equatable { var name: String; var phone: String }
        let storage = try makeStorage(fileName: "info")
        let info = Info(name: "Alice", phone: "555")
        try storage.store(info)
        let fetched: Info = try storage.fetchValue()
        XCTAssertEqual(fetched, info)
    }

    // MARK: - Raw Data

    func testStoreAndFetchData() throws {
        let storage = try makeStorage(fileName: "raw")
        let data = Data("binary content".utf8)
        try storage.storeData(data)
        let fetched = try storage.fetchData()
        XCTAssertEqual(fetched, data)
    }

    // MARK: - Remove

    func testRemoveDeletesFile() throws {
        let storage = try makeStorage(fileName: "removable")
        try storage.store("temp")
        XCTAssertTrue(storage.fileExists)
        try storage.remove()
        XCTAssertFalse(storage.fileExists)
    }

    // MARK: - Encryption

    func testEncryptedRoundTrip() throws {
        let key = Encryption.generateKey()
        let enc = Encryption(key: key)
        let storage = try makeStorage(fileName: "encrypted", encryption: enc)
        let items: Set<StoredObject> = [StoredObject(name: "secret", value: 42)]
        try storage.store(collection: items)
        let fetched: Set<StoredObject> = try storage.fetchCollection()
        XCTAssertEqual(fetched.first?.name, "secret")
    }

    func testWrongKeyFailsDecryption() throws {
        let enc1 = Encryption(key: Encryption.generateKey())
        let enc2 = Encryption(key: Encryption.generateKey())
        let s1 = try makeStorage(fileName: "enc1", encryption: enc1)
        try s1.store("secret")
        let s2 = try Storage(
            destination: .custom(tempDir.path),
            fileName: "enc1",
            encryption: enc2
        )
        XCTAssertThrowsError(try s2.fetchValue() as String)
    }

    // MARK: - File does not exist

    func testFetchThrowsWhenNoFile() throws {
        let storage = try makeStorage(fileName: "missing")
        XCTAssertThrowsError(try storage.fetchValue() as String)
    }

    // MARK: - Last updated

    func testLastUpdated() throws {
        let storage = try makeStorage(fileName: "dated")
        XCTAssertNil(storage.lastUpdated)
        try storage.store("data")
        XCTAssertNotNil(storage.lastUpdated)
    }
}
