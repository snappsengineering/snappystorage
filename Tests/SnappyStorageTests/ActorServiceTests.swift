import XCTest
@testable import SnappyStorage

final class ActorServiceTests: XCTestCase {

    // MARK: - Properties

    private var tempDir: URL!

    // MARK: - Lifecycle

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

    // MARK: - Read and write

    func testSaveAndFetch() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let obj = StoredObject(name: "async", value: 1)
        await svc.save(obj)
        let all = await svc.fetchAll()
        XCTAssertEqual(all.count, 1)
        let fetched = await svc.fetch(id: obj.id)
        XCTAssertEqual(fetched?.name, "async")
    }

    func testDelete() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let obj = StoredObject(name: "del", value: 0)
        await svc.save(obj)
        await svc.delete(obj)
        let all = await svc.fetchAll()
        XCTAssertTrue(all.isEmpty)
    }

    func testSaveMultiple() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let items: Set<StoredObject> = [
            StoredObject(name: "a", value: 1),
            StoredObject(name: "b", value: 2)
        ]
        await svc.save(items)
        let all = await svc.fetchAll()
        XCTAssertEqual(all.count, 2)
    }

    func testRemoveFile() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        await svc.save(StoredObject(name: "temp", value: 0))
        try await svc.removeFile()
        let reloaded = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let all = await reloaded.fetchAll()
        XCTAssertTrue(all.isEmpty)
    }
}
