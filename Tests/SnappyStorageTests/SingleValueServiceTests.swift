import XCTest
@testable import SnappyStorage

final class SingleValueServiceTests: XCTestCase {

    // MARK: - Properties

    private var tempDir: URL!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnappySVSTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Read and write

    func testSaveAndFetch() throws {
        struct AppConfig: Codable, Equatable { var name: String; var version: String }
        let svc = SingleValueService<AppConfig>(
            destination: .custom(tempDir.path),
            fileName: "AppConfig"
        )
        let config = AppConfig(name: "Alice", version: "1.0")
        try svc.save(config)
        let fetched = svc.fetch()
        XCTAssertEqual(fetched, config)
    }

    func testFetchReturnsNilWhenEmpty() {
        let svc = SingleValueService<String>(
            destination: .custom(tempDir.path),
            fileName: "empty"
        )
        XCTAssertNil(svc.fetch())
    }

    func testRemove() throws {
        let svc = SingleValueService<Bool>(
            destination: .custom(tempDir.path),
            fileName: "flag"
        )
        try svc.save(true)
        try svc.remove()
        XCTAssertNil(svc.fetch())
    }

    // MARK: - Encryption

    func testEncryptedSingleValue() throws {
        let enc = Encryption(key: Encryption.generateKey())
        let svc = SingleValueService<String>(
            destination: .custom(tempDir.path),
            fileName: "secret",
            encryption: enc
        )
        try svc.save("classified")
        XCTAssertEqual(svc.fetch(), "classified")
    }

    // MARK: - load() vs fetch()

    func testLoadReturnsNilWhenMissing() throws {
        let svc = SingleValueService<String>(destination: .custom(tempDir.path), fileName: "missing")
        XCTAssertNil(try svc.load())
    }

    func testLoadThrowsOnCorruptData() throws {
        let storage = Storage(location: Location(destination: .custom(tempDir.path), file: File(name: "corrupt")))
        try storage.write(Data("not json".utf8))
        let svc = SingleValueService<String>(destination: .custom(tempDir.path), fileName: "corrupt")
        XCTAssertThrowsError(try svc.load())
        // fetch() stays lenient — returns nil instead of throwing.
        XCTAssertNil(svc.fetch())
    }
}
