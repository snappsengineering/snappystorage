import XCTest
@testable import SnappyStorage

final class LoadStateAndCoalescingTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnappyLoadState-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testLoadStateDistinguishesEmptyAndFailed() async {
        let service = Service<StoredObject>(destination: .custom(tempDir.path))
        XCTAssertEqual(service.loadState, .notLoaded)

        let empty = await service.load()
        XCTAssertEqual(empty, .empty)
        XCTAssertEqual(service.loadState, .empty)
        XCTAssertNil(service.loadError)

        let storage = Storage(location: Location(destination: .custom(tempDir.path), file: File(name: "StoredObject")))
        try? storage.write(Data("not-json".utf8))
        let broken = Service<StoredObject>(destination: .custom(tempDir.path))
        let failed = await broken.load()
        XCTAssertEqual(failed, .failed)
        XCTAssertEqual(broken.loadState, .failed)
        XCTAssertNotNil(broken.loadError)
    }

    func testSaveAfterLoadFailureDoesNotOverwriteFile() throws {
        let storage = Storage(location: Location(destination: .custom(tempDir.path), file: File(name: "StoredObject")))
        let corrupt = Data("corrupt-on-disk".utf8)
        try storage.write(corrupt)

        let service = Service<StoredObject>(destination: .custom(tempDir.path))
        _ = service.fetchAll()
        service.save(StoredObject(name: "should-not-write", value: 1))
        service.flush()

        XCTAssertEqual(try storage.read(), corrupt)
        XCTAssertEqual(service.lastError as? ServiceError, .persistBlockedByLoadFailure)
    }

    func testCoalescedPersistsOnceAfterBurst() async throws {
        let config = ServiceConfiguration(persistCoalesceInterval: 0.05)
        let service = Service<StoredObject>(destination: .custom(tempDir.path), configuration: config)
        for i in 0..<5 {
            service.save(StoredObject(name: "item-\(i)", value: i))
        }
        try await Task.sleep(for: .milliseconds(120))
        service.flush()

        let reloaded = Service<StoredObject>(destination: .custom(tempDir.path))
        XCTAssertEqual(reloaded.count, 5)
    }

    func testBackupCreatesSiblingFile() throws {
        let service = Service<StoredObject>(destination: .custom(tempDir.path))
        service.save(StoredObject(name: "backup-me", value: 1))
        service.flush()
        let backupURL = try XCTUnwrap(service.backupFile())
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))
        XCTAssertTrue(backupURL.lastPathComponent.hasSuffix("json.bak"))
    }

    func testSetExactlyOne() {
        let service = Service<StoredObject>(destination: .custom(tempDir.path))
        let solo = StoredObject(name: "only", value: 1)
        service.setExactlyOne(solo)
        XCTAssertEqual(service.count, 1)
        service.setExactlyOne(nil)
        XCTAssertEqual(service.count, 0)
    }

    func testPreloadLoadsBeforeMainThreadRead() async {
        let service = Service<StoredObject>(destination: .custom(tempDir.path))
        service.save(StoredObject(name: "bg", value: 1))
        service.unload()

        let fresh = Service<StoredObject>(destination: .custom(tempDir.path))
        fresh.preload()
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(fresh.loadState, .loaded(count: 1))
    }
}
