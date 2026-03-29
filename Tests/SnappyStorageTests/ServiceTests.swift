import XCTest
@testable import SnappyStorage

final class ServiceTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnappyServiceTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func makeService() -> Service<StoredObject> {
        Service<StoredObject>(destination: .custom(tempDir.path))
    }

    func testSaveAndFetch() {
        let service = makeService()
        let obj = StoredObject(name: "test", value: 1)
        service.save(obj)
        XCTAssertEqual(service.fetchAll().count, 1)
        XCTAssertEqual(service.fetch(id: obj.id)?.name, "test")
    }

    func testSaveMultiple() {
        let service = makeService()
        let items: Set<StoredObject> = [
            StoredObject(name: "a", value: 1),
            StoredObject(name: "b", value: 2)
        ]
        service.save(items)
        XCTAssertEqual(service.fetchAll().count, 2)
    }

    func testUpdateExisting() {
        let service = makeService()
        let id = "fixed-id"
        service.save(StoredObject(id: id, name: "old", value: 1))
        service.save(StoredObject(id: id, name: "new", value: 2))
        XCTAssertEqual(service.fetchAll().count, 1)
    }

    func testDelete() {
        let service = makeService()
        let obj = StoredObject(name: "delete-me", value: 0)
        service.save(obj)
        XCTAssertEqual(service.fetchAll().count, 1)
        service.delete(obj)
        XCTAssertTrue(service.fetchAll().isEmpty)
    }

    func testPersistenceAcrossInstances() {
        let s1 = makeService()
        s1.save(StoredObject(name: "persist", value: 99))

        let s2 = Service<StoredObject>(destination: .custom(tempDir.path))
        XCTAssertEqual(s2.fetchAll().count, 1)
        XCTAssertEqual(s2.fetchAll().first?.name, "persist")
    }

    func testRemoveFile() throws {
        let service = makeService()
        service.save(StoredObject(name: "temp", value: 0))
        try service.removeFile()
        let s2 = Service<StoredObject>(destination: .custom(tempDir.path))
        XCTAssertTrue(s2.fetchAll().isEmpty)
    }

    func testReload() {
        let service = makeService()
        service.save(StoredObject(name: "a", value: 1))
        XCTAssertEqual(service.fetchAll().count, 1)
        service.reload()
        XCTAssertEqual(service.fetchAll().count, 1)
    }
}
