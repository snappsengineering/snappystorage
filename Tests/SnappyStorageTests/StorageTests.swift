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

    // MARK: - Randomized round-trips (fuzz-lite)

    /// Random content per run rather than one fixed fixture, to catch encoding/encryption
    /// edge cases (empty strings, unicode, extreme ints) that hand-picked values could miss.
    private func randomStoredObjects(count: Int) -> [StoredObject] {
        let unicodePool = ["", "plain", "emoji-😀🚀", "quote-\"escaped\"", "newline-\nvalue", "unicode-日本語", "null-byte-\0-ish"]
        return (0..<count).map { _ in
            StoredObject(
                name: unicodePool.randomElement()!,
                value: Int.random(in: Int.min...Int.max)
            )
        }
    }

    func testPersistenceRoundTripWithRandomizedContentUnencrypted() throws {
        for _ in 0..<10 {
            let persistence = makePersistence(fileName: "fuzz-plain-\(UUID().uuidString)")
            let originals = randomStoredObjects(count: 5)
            try persistence.write(originals)
            let loaded = try persistence.read([StoredObject].self)
            XCTAssertEqual(Set(loaded.map(\.id)), Set(originals.map(\.id)))
            for original in originals {
                let match = loaded.first { $0.id == original.id }
                XCTAssertEqual(match?.name, original.name)
                XCTAssertEqual(match?.value, original.value)
            }
        }
    }

    func testPersistenceRoundTripWithRandomizedContentEncrypted() throws {
        for _ in 0..<10 {
            let enc = Encryption(key: Encryption.generateKey())
            let persistence = makePersistence(fileName: "fuzz-enc-\(UUID().uuidString)", encryption: enc)
            let originals = randomStoredObjects(count: 5)
            try persistence.write(originals)
            let loaded = try persistence.read([StoredObject].self)
            XCTAssertEqual(Set(loaded.map(\.id)), Set(originals.map(\.id)))
            for original in originals {
                let match = loaded.first { $0.id == original.id }
                XCTAssertEqual(match?.name, original.name)
                XCTAssertEqual(match?.value, original.value)
            }
        }
    }

    func testPersistenceRoundTripWithEmptyCollection() throws {
        let persistence = makePersistence(fileName: "fuzz-empty")
        try persistence.write([StoredObject]())
        XCTAssertEqual(try persistence.read([StoredObject].self).count, 0)
    }
}
