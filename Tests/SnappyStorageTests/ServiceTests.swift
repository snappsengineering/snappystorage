import XCTest
@testable import SnappyStorage

final class ServiceTests: XCTestCase {

    // MARK: - Properties

    private var tempDir: URL!

    // MARK: - Lifecycle

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

    // MARK: - Helpers

    private func makeService() -> Service<StoredObject> {
        Service<StoredObject>(destination: .custom(tempDir.path))
    }

    // MARK: - Read and write

    func testSaveAndFetch() {
        let service = makeService()
        let obj = StoredObject(name: "test", value: 1)
        service.save(obj)
        XCTAssertEqual(service.fetchAll().count, 1)
        XCTAssertEqual(service.fetch(id: obj.id)?.name, "test")
    }

    func testCollectionPropertyLazyLoads() {
        let service = makeService()
        service.save(StoredObject(name: "via-collection", value: 1))
        XCTAssertEqual(service.collection.count, 1)
        XCTAssertEqual(service.collection.first?.name, "via-collection")
    }

    func testReplaceWithoutPriorLoad() {
        let service = makeService()
        let item = StoredObject(name: "fresh-replace", value: 1)
        service.replace([item])
        XCTAssertEqual(service.fetchAll().count, 1)
        let reloaded = Service<StoredObject>(destination: .custom(tempDir.path))
        XCTAssertEqual(reloaded.fetch(id: item.id)?.name, "fresh-replace")
    }

    func testPersistAfterUnloadWritesCurrentSnapshot() {
        let service = makeService()
        service.save(StoredObject(name: "before-unload", value: 1))
        service.unload()
        service.persist()
        let reloaded = Service<StoredObject>(destination: .custom(tempDir.path))
        XCTAssertTrue(reloaded.fetchAll().isEmpty)
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

    func testDeleteMultiple() {
        let service = makeService()
        let a = StoredObject(name: "a", value: 1)
        let b = StoredObject(name: "b", value: 2)
        let c = StoredObject(name: "c", value: 3)
        service.save([a, b, c])
        service.delete([a, c])
        XCTAssertEqual(service.fetchAll().count, 1)
        XCTAssertEqual(service.fetch(id: b.id)?.name, "b")
        XCTAssertNil(service.fetch(id: a.id))

        let reloaded = Service<StoredObject>(destination: .custom(tempDir.path))
        XCTAssertEqual(reloaded.fetchAll().count, 1)
        XCTAssertEqual(reloaded.fetchAll().first?.name, "b")
    }

    func testReplaceSwapsCollection() {
        let service = makeService()
        let old = StoredObject(name: "old", value: 1)
        service.save(old)
        let replacement = StoredObject(name: "new", value: 2)
        service.replace([replacement])
        XCTAssertEqual(service.fetchAll().count, 1)
        XCTAssertNil(service.fetch(id: old.id))
        XCTAssertEqual(service.fetch(id: replacement.id)?.name, "new")

        let reloaded = Service<StoredObject>(destination: .custom(tempDir.path))
        XCTAssertEqual(reloaded.fetchAll().count, 1)
        XCTAssertNil(reloaded.fetch(id: old.id))
    }

    func testBatchMutatesAndPersists() {
        let service = makeService()
        let keep = StoredObject(name: "keep", value: 1)
        let drop = StoredObject(name: "drop", value: 2)
        service.save([keep, drop])
        service.batch { items in
            items.remove(drop)
            items.insert(StoredObject(name: "added", value: 3))
        }
        XCTAssertEqual(service.count, 2)
        XCTAssertNil(service.fetch(id: drop.id))
        XCTAssertNotNil(service.fetch(id: keep.id))

        let reloaded = Service<StoredObject>(destination: .custom(tempDir.path))
        XCTAssertEqual(reloaded.count, service.count)
        XCTAssertEqual(reloaded.fetchAll().count, 2)
    }

    func testCountMatchesFetchAll() {
        let service = makeService()
        XCTAssertEqual(service.count, 0)
        service.save(StoredObject(name: "a", value: 1))
        XCTAssertEqual(service.count, 1)
        XCTAssertEqual(service.count, service.fetchAll().count)
        service.delete(service.fetchAll())
        XCTAssertEqual(service.count, 0)
        service.unload()
        XCTAssertEqual(service.count, 0)
    }

    func testFetchIdNilWhenMissing() {
        let service = makeService()
        XCTAssertNil(service.fetch(id: "never-existed"))
        let obj = StoredObject(name: "x", value: 1)
        service.save(obj)
        service.delete(obj)
        XCTAssertNil(service.fetch(id: obj.id))
    }

    func testLazyLoadDefersCorruptFileDetection() throws {
        let storage = Storage(location: Location(destination: .custom(tempDir.path), file: File(name: "StoredObject")))
        try storage.write(Data("not json".utf8))

        let service = Service<StoredObject>(destination: .custom(tempDir.path))
        XCTAssertNil(service.loadError)

        _ = service.count
        XCTAssertNotNil(service.loadError)
        XCTAssertTrue(service.fetchAll().isEmpty)
    }

    func testUnloadDropsCacheAndReloadsFromDisk() {
        let service = makeService()
        service.save(StoredObject(name: "cached", value: 1))
        service.unload()
        XCTAssertEqual(service.fetchAll().count, 1)
        XCTAssertEqual(service.fetchAll().first?.name, "cached")
    }

    func testUnloadThenExternalCorruptionSurfacesOnNextRead() throws {
        let service = makeService()
        service.save(StoredObject(name: "good", value: 1))
        service.unload()

        let storage = Storage(location: Location(destination: .custom(tempDir.path), file: File(name: "StoredObject")))
        try storage.write(Data("corrupt".utf8))

        XCTAssertTrue(service.fetchAll().isEmpty)
        XCTAssertNotNil(service.loadError)
    }

    // MARK: - Persistence

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

    // MARK: - Encryption

    func testEncryptedRoundTrip() {
        let enc = Encryption(key: Encryption.generateKey())
        let svc = Service<StoredObject>(destination: .custom(tempDir.path), encryption: enc)
        svc.save(StoredObject(name: "secret", value: 42))
        let loaded = Service<StoredObject>(destination: .custom(tempDir.path), encryption: enc)
        XCTAssertEqual(loaded.fetchAll().first?.name, "secret")
    }

    func testWrongKeyFailsDecryption() throws {
        let enc1 = Encryption(key: Encryption.generateKey())
        let enc2 = Encryption(key: Encryption.generateKey())
        let persistence = Persistence(
            destination: .custom(tempDir.path),
            fileName: "StoredObject",
            fileExtension: "json",
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            encryption: enc1
        )
        try persistence.write([StoredObject(name: "secret", value: 1)])

        let wrongKeyPersistence = Persistence(
            destination: .custom(tempDir.path),
            fileName: "StoredObject",
            fileExtension: "json",
            encoder: JSONEncoder(),
            decoder: JSONDecoder(),
            encryption: enc2
        )
        XCTAssertThrowsError(try wrongKeyPersistence.read([StoredObject].self))
    }

    func testMissingFileReturnsEmptyCollection() {
        let service = Service<StoredObject>(destination: .custom(tempDir.path))
        XCTAssertTrue(service.fetchAll().isEmpty)
        XCTAssertNil(service.loadError)
    }

    // MARK: - Error surfacing

    func testCorruptFileSetsLoadErrorAndStaysEmpty() throws {
        let storage = Storage(location: Location(destination: .custom(tempDir.path), file: File(name: "StoredObject")))
        try storage.write(Data("not json".utf8))

        let service = Service<StoredObject>(destination: .custom(tempDir.path))
        XCTAssertTrue(service.fetchAll().isEmpty)
        XCTAssertNotNil(service.loadError)
        // File is left untouched on load failure.
        XCTAssertEqual(try storage.read(), Data("not json".utf8))
    }

    func testLastErrorClearsOnSuccessfulPersist() {
        let service = makeService()
        service.save(StoredObject(name: "a", value: 1))
        XCTAssertNil(service.lastError)
    }

    func testLastErrorSetWhenWriteFails() throws {
        // A file blocking the destination folder makes every write fail.
        let blocker = tempDir.appendingPathComponent("blocker")
        try Data("x".utf8).write(to: blocker)
        let service = Service<StoredObject>(destination: .custom(blocker.path))
        service.save(StoredObject(name: "a", value: 1))
        XCTAssertNotNil(service.lastError)
    }

    // MARK: - Change hook

    func testStep1APISurface() throws {
        let service = makeService()
        let a = StoredObject(name: "a", value: 1)
        let b = StoredObject(name: "b", value: 2)
        service.replace([a])
        service.batch { $0.insert(b) }
        service.save(StoredObject(name: "c", value: 3))
        service.save([StoredObject(name: "d", value: 4)])
        service.delete(a)
        service.delete([b])
        _ = service.count
        _ = service.collection
        _ = service.fetch(id: "missing")
        service.unload()
        service.reload()
        try service.removeFile()
    }

    func testCollectionDidChangeOverride() {
        final class TrackingService: Service<StoredObject> {
            var changeCount = 0
            override func collectionDidChange() { changeCount += 1 }
        }
        let service = TrackingService(destination: .custom(tempDir.path))
        service.save(StoredObject(name: "a", value: 1))
        service.delete(service.fetchAll().first!)
        XCTAssertEqual(service.changeCount, 2)
    }
}
