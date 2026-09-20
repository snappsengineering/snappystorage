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

    func testStep1APISurface() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let a = StoredObject(name: "a", value: 1)
        let b = StoredObject(name: "b", value: 2)
        await svc.replace([a])
        await svc.batch { $0.insert(b) }
        await svc.save(StoredObject(name: "c", value: 3))
        await svc.save([StoredObject(name: "d", value: 4)])
        await svc.delete(a)
        await svc.delete([b])
        _ = await svc.count
        _ = await svc.fetch(id: "missing")
        await svc.unload()
        try await svc.removeFile()
    }

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

    func testPersistAfterUnloadWritesEmptySnapshot() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        await svc.save(StoredObject(name: "before", value: 1))
        await svc.unload()
        await svc.persist()
        let reloaded = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let all = await reloaded.fetchAll()
        XCTAssertTrue(all.isEmpty)
    }

    func testReplaceWithoutPriorLoad() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let item = StoredObject(name: "fresh-replace", value: 1)
        await svc.replace([item])
        let count = await svc.count
        XCTAssertEqual(count, 1)
    }

    func testWriteFailureStillYieldsSnapshot() async throws {
        let blocker = tempDir.appendingPathComponent("blocker")
        try Data("x".utf8).write(to: blocker)
        let svc = ActorService<StoredObject>(destination: .custom(blocker.path))
        var iterator = svc.updates.makeAsyncIterator()
        let initial = await iterator.next()
        XCTAssertEqual(initial, [])
        await svc.save(StoredObject(name: "a", value: 1))
        let afterFailedSave = await iterator.next()
        XCTAssertEqual(afterFailedSave?.count, 1)
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

    func testDeleteMultiple() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let a = StoredObject(name: "a", value: 1)
        let b = StoredObject(name: "b", value: 2)
        let c = StoredObject(name: "c", value: 3)
        await svc.save([a, b, c])
        await svc.delete([a, c])
        let all = await svc.fetchAll()
        XCTAssertEqual(all.count, 1)
        let fetchedB = await svc.fetch(id: b.id)
        XCTAssertEqual(fetchedB?.name, "b")

        let reloaded = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let reloadedAll = await reloaded.fetchAll()
        XCTAssertEqual(reloadedAll.count, 1)
    }

    func testReplaceSwapsCollection() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let old = StoredObject(name: "old", value: 1)
        await svc.save(old)
        let replacement = StoredObject(name: "new", value: 2)
        await svc.replace([replacement])
        let oldFetched = await svc.fetch(id: old.id)
        XCTAssertNil(oldFetched)
        let replacementFetched = await svc.fetch(id: replacement.id)
        XCTAssertEqual(replacementFetched?.name, "new")

        let reloaded = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let reloadedAll = await reloaded.fetchAll()
        XCTAssertEqual(reloadedAll.count, 1)
        let oldOnReload = await reloaded.fetch(id: old.id)
        XCTAssertNil(oldOnReload)
    }

    func testBatchMutatesAndPersists() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let keep = StoredObject(name: "keep", value: 1)
        let drop = StoredObject(name: "drop", value: 2)
        await svc.save([keep, drop])
        await svc.batch { items in
            items.remove(drop)
            items.insert(StoredObject(name: "added", value: 3))
        }
        let count = await svc.count
        XCTAssertEqual(count, 2)
        let reloaded = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let reloadedCount = await reloaded.count
        XCTAssertEqual(reloadedCount, 2)
    }

    func testCountMatchesFetchAll() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let emptyCount = await svc.count
        XCTAssertEqual(emptyCount, 0)
        await svc.save(StoredObject(name: "a", value: 1))
        let count = await svc.count
        let fetched = await svc.fetchAll()
        XCTAssertEqual(count, fetched.count)
        await svc.unload()
        let countAfterUnload = await svc.count
        XCTAssertEqual(countAfterUnload, 1)
    }

    func testFetchIdNilWhenMissing() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let missing = await svc.fetch(id: "missing")
        XCTAssertNil(missing)
        let obj = StoredObject(name: "x", value: 1)
        await svc.save(obj)
        await svc.delete(obj)
        let afterDelete = await svc.fetch(id: obj.id)
        XCTAssertNil(afterDelete)
    }

    func testLazyLoadDefersCorruptFileDetection() async throws {
        let storage = Storage(location: Location(destination: .custom(tempDir.path), file: File(name: "StoredObject")))
        try storage.write(Data("not json".utf8))

        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let errorBeforeRead = await svc.loadError
        XCTAssertNil(errorBeforeRead)

        _ = await svc.count
        let loadErrorAfterCount = await svc.loadError
        XCTAssertNotNil(loadErrorAfterCount)
        let all = await svc.fetchAll()
        XCTAssertTrue(all.isEmpty)
    }

    func testUnloadDropsCacheAndReloadsFromDisk() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        await svc.save(StoredObject(name: "cached", value: 1))
        await svc.unload()
        let all = await svc.fetchAll()
        XCTAssertEqual(all.count, 1)
    }

    func testUnloadThenExternalCorruptionSurfacesOnNextRead() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        await svc.save(StoredObject(name: "good", value: 1))
        await svc.unload()

        let storage = Storage(location: Location(destination: .custom(tempDir.path), file: File(name: "StoredObject")))
        try storage.write(Data("corrupt".utf8))

        let all = await svc.fetchAll()
        XCTAssertTrue(all.isEmpty)
        let loadError = await svc.loadError
        XCTAssertNotNil(loadError)
    }

    func testUpdatesStreamYieldsEmptyThenLoaded() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        var iterator = svc.updates.makeAsyncIterator()
        let initial = await iterator.next()
        XCTAssertEqual(initial, [])

        let obj = StoredObject(name: "stream", value: 1)
        await svc.save(obj)
        let afterSave = await iterator.next()
        XCTAssertEqual(afterSave?.count, 1)

        await svc.unload()
        _ = await svc.fetchAll()
        let afterReload = await iterator.next()
        XCTAssertEqual(afterReload?.count, 1)
    }

    func testCorruptFileSetsLoadErrorAndStaysEmpty() async throws {
        let storage = Storage(location: Location(destination: .custom(tempDir.path), file: File(name: "StoredObject")))
        try storage.write(Data("not json".utf8))

        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let all = await svc.fetchAll()
        XCTAssertTrue(all.isEmpty)
        let loadError = await svc.loadError
        XCTAssertNotNil(loadError)
        XCTAssertEqual(try storage.read(), Data("not json".utf8))
    }

    func testMissingFileReturnsEmptyCollection() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let all = await svc.fetchAll()
        XCTAssertTrue(all.isEmpty)
        let loadError = await svc.loadError
        XCTAssertNil(loadError)
    }
}
