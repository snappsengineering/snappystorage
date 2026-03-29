import XCTest
@testable import SnappyStorage

final class SingleValueServiceTests: XCTestCase {

    private var tempDir: URL!

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
        XCTAssertTrue(svc.exists)
        try svc.remove()
        XCTAssertFalse(svc.exists)
        XCTAssertNil(svc.fetch())
    }

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
}
