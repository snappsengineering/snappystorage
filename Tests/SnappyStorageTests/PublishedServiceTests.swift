import XCTest
@testable import SnappyStorage

final class PublishedServiceTests: XCTestCase {

    // MARK: - Properties

    private var tempDir: URL!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnappyPublishedTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeService() -> PublishedService<StoredObject> {
        PublishedService<StoredObject>(destination: .custom(tempDir.path))
    }

    // MARK: - Tests

    func testPublishedStartsWithCollection() {
        let service = makeService()
        service.save(StoredObject(name: "seed", value: 1))
        let reloaded = PublishedService<StoredObject>(destination: .custom(tempDir.path))
        XCTAssertEqual(reloaded.published.count, 1)
    }

    func testPublishedUpdatesOnSave() {
        let service = makeService()
        service.save(StoredObject(name: "a", value: 1))
        XCTAssertEqual(service.published.count, 1)
    }

    func testPublishedUpdatesOnDelete() {
        let service = makeService()
        let obj = StoredObject(name: "a", value: 1)
        service.save(obj)
        service.delete(obj)
        XCTAssertTrue(service.published.isEmpty)
    }
}
