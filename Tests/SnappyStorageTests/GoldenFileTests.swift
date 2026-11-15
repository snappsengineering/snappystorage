import XCTest
@testable import SnappyStorage

/// Fixtures match SnappyStorage 2.0.0 on-disk JSON-array layout (`[T]` in one file).
final class GoldenFileTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnappyGolden-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testDecodePlainJSONV2Fixture() async throws {
        let fixture = """
        [{"id":"golden-a","name":"alpha","value":1},{"id":"golden-b","name":"beta","value":2}]
        """
        let storage = Storage(location: Location(destination: .custom(tempDir.path), file: File(name: "StoredObject")))
        try storage.write(Data(fixture.utf8))

        let service = Service<StoredObject>(destination: .custom(tempDir.path))
        _ = await service.load()
        XCTAssertEqual(service.loadState, .loaded(count: 2))
        XCTAssertEqual(service.fetch(id: "golden-a")?.name, "alpha")
        XCTAssertEqual(service.fetch(id: "golden-b")?.value, 2)
    }

    func testRoundTripMatchesV2Format() throws {
        let service = Service<StoredObject>(destination: .custom(tempDir.path))
        service.save([
            StoredObject(id: "r1", name: "round", value: 7),
            StoredObject(id: "r2", name: "trip", value: 8)
        ])
        service.flush()

        let persistence = Persistence(
            destination: .custom(tempDir.path),
            fileName: "StoredObject",
            fileExtension: "json",
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            encryption: nil
        )
        let decoded = try persistence.read([StoredObject].self)
        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(Set(decoded).map(\.id).sorted(), ["r1", "r2"])
    }

    func testEncryptedRoundTripV2Layout() throws {
        let key = Encryption.generateKey()
        let enc = Encryption(key: key)
        let persistence = Persistence(
            destination: .custom(tempDir.path),
            fileName: "StoredObject",
            fileExtension: "json",
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            encryption: enc
        )
        try persistence.write([StoredObject(id: "enc-1", name: "sealed", value: 3)])

        let reloaded = Service<StoredObject>(destination: .custom(tempDir.path), encryption: enc)
        XCTAssertEqual(reloaded.fetch(id: "enc-1")?.name, "sealed")

        let raw = try Storage(location: Location(destination: .custom(tempDir.path), file: File(name: "StoredObject"))).read()
        XCTAssertFalse(raw.starts(with: Data("[".utf8)), "encrypted payload must not be plain JSON")
        XCTAssertEqual(try persistence.read([StoredObject].self).first?.value, 3)
    }
}
