import XCTest
@testable import SnappyStorage

final class ActorServiceTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnappyActorTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testSaveAndFetch() async throws {
        let svc = try ActorService<StoredObject>(destination: .custom(tempDir.path))
        let obj = StoredObject(name: "async", value: 1)
        await svc.save(obj)
        let all = await svc.fetchAll()
        XCTAssertEqual(all.count, 1)
        let fetched = await svc.fetch(id: obj.id)
        XCTAssertEqual(fetched?.name, "async")
    }

    func testDelete() async throws {
        let svc = try ActorService<StoredObject>(destination: .custom(tempDir.path))
        let obj = StoredObject(name: "del", value: 0)
        await svc.save(obj)
        await svc.delete(obj)
        let all = await svc.fetchAll()
        XCTAssertTrue(all.isEmpty)
    }
}
