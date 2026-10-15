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

    // MARK: - Concurrency

    /// Many tasks calling `save` on distinct items concurrently. The actor serializes every
    /// call internally, so no write should be lost regardless of interleaving — this pins
    /// down that guarantee rather than just exercising the line.
    func testConcurrentSavesOfDistinctItemsAllPersist() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let items = (0..<50).map { StoredObject(name: "item-\($0)", value: $0) }

        await withTaskGroup(of: Void.self) { group in
            for item in items {
                group.addTask { await svc.save(item) }
            }
        }

        let count = await svc.count
        XCTAssertEqual(count, items.count)
        for item in items {
            let fetched = await svc.fetch(id: item.id)
            XCTAssertEqual(fetched?.value, item.value)
        }

        let reloaded = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let reloadedCount = await reloaded.count
        XCTAssertEqual(reloadedCount, items.count, "every concurrent save must have persisted to disk")
    }

    /// Interleaved save/delete of the *same* item id from concurrent tasks. Actor isolation
    /// guarantees each op runs atomically, so the only requirement is that the end state
    /// matches *some* valid serialization — not that it crashes, corrupts the index, or drops
    /// the write entirely.
    func testConcurrentSaveAndDeleteOfSameItemStaysConsistent() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let shared = StoredObject(id: "shared", name: "shared", value: 0)

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<25 {
                group.addTask { await svc.save(StoredObject(id: "shared", name: "v\(i)", value: i)) }
                group.addTask { await svc.delete(shared) }
            }
        }

        // Whatever the final state, index and collection must agree (no desync).
        let count = await svc.count
        let all = await svc.fetchAll()
        XCTAssertEqual(count, all.count)
        if let fetched = await svc.fetch(id: "shared") {
            XCTAssertTrue(all.contains(fetched))
        } else {
            XCTAssertFalse(all.contains { $0.id == "shared" })
        }
    }

    /// `unload()` racing with in-flight `save`s must not crash or corrupt in-memory state —
    /// whatever lands last (unload or a save) fully determines the visible state, with no
    /// partial/torn index.
    func testConcurrentUnloadDuringSavesStaysConsistent() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let items = (0..<20).map { StoredObject(name: "u-\($0)", value: $0) }

        await withTaskGroup(of: Void.self) { group in
            for item in items {
                group.addTask { await svc.save(item) }
            }
            group.addTask { await svc.unload() }
        }

        let count = await svc.count
        let all = await svc.fetchAll()
        XCTAssertEqual(count, all.count, "index and collection must never disagree after a race with unload()")
    }

    /// Concurrent `replace(_:)` calls each install a full snapshot; the actor serializes them,
    /// so the final state must be exactly one of the inputs, not a merge or partial mix.
    func testConcurrentReplacesResultInOneCompleteSnapshot() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        let snapshotA: Set<StoredObject> = [StoredObject(id: "a1", name: "a1", value: 1)]
        let snapshotB: Set<StoredObject> = [StoredObject(id: "b1", name: "b1", value: 2), StoredObject(id: "b2", name: "b2", value: 3)]

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await svc.replace(snapshotA) }
            group.addTask { await svc.replace(snapshotB) }
        }

        let all = await svc.fetchAll()
        XCTAssertTrue(all == snapshotA || all == snapshotB, "final state must be exactly one full snapshot, not a mix")
    }

    /// `updates` is documented as a single-buffer, single-consumer stream (`.bufferingNewest(1)`).
    /// Confirms a *second* iterator created after values have already been produced does not
    /// hang and does not replay stale history — it only sees what's buffered from here on.
    /// (Concurrently awaiting `.next()` on two live iterators of the same `AsyncStream` is
    /// undefined behavior upstream and is intentionally not exercised here.)
    func testSecondIteratorCreatedLaterDoesNotReplayHistory() async throws {
        let svc = ActorService<StoredObject>(destination: .custom(tempDir.path))
        var iteratorA = svc.updates.makeAsyncIterator()
        let initialA = await iteratorA.next()
        XCTAssertEqual(initialA, [])

        await svc.save(StoredObject(name: "one", value: 1))
        let afterSave = await iteratorA.next()
        XCTAssertEqual(afterSave?.count, 1)

        // A fresh iterator created now should get the *next* yield, not "one" again.
        var iteratorB = svc.updates.makeAsyncIterator()
        await svc.save(StoredObject(name: "two", value: 2))
        let fromB = await iteratorB.next()
        XCTAssertEqual(fromB?.count, 2)
    }
}
