import XCTest
@testable import SnappyStorage

final class FileManagerExtensionsTests: XCTestCase {

    // MARK: - Properties

    private var tempDir: URL!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnappyFMTests-\(UUID().uuidString)")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - ensureDirectory

    func testEnsureDirectoryCreatesMissingFolder() throws {
        let fileURL = tempDir.appendingPathComponent("nested/file.json")
        try Data("x".utf8).writeAtomic(to: fileURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    // MARK: - removeIfExists

    func testRemoveIfExistsNoOpWhenMissing() throws {
        let missing = tempDir.appendingPathComponent("nope.json")
        XCTAssertNoThrow(try FileManager.default.removeIfExists(at: missing))
    }

    func testRemoveIfExistsThrowsIOErrorWhenRemoveFails() throws {
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let url = tempDir.appendingPathComponent("immutable")
        try Data("x".utf8).write(to: url)
        try FileManager.default.setAttributes([.immutable: true], ofItemAtPath: url.path)
        defer { try? FileManager.default.setAttributes([.immutable: false], ofItemAtPath: url.path) }
        XCTAssertThrowsError(try FileManager.default.removeIfExists(at: url)) { error in
            guard case StorageError.ioError = error else {
                return XCTFail("Expected ioError, got \(error)")
            }
        }
    }

    func testWriteAtomicThrowsIOErrorWhenWriteFails() throws {
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let blocker = tempDir.appendingPathComponent("blocker")
        try Data("x".utf8).write(to: blocker)
        let blockedFile = blocker.appendingPathComponent("nested.json")
        XCTAssertThrowsError(try Data("y".utf8).writeAtomic(to: blockedFile)) { error in
            guard case StorageError.ioError = error else {
                return XCTFail("Expected ioError, got \(error)")
            }
        }
    }

    // MARK: - data(at:)

    func testDataAtThrowsFileDoesNotExist() {
        let missing = tempDir.appendingPathComponent("nope.json")
        XCTAssertThrowsError(try FileManager.default.data(at: missing)) { error in
            guard case StorageError.fileDoesNotExist = error else {
                return XCTFail("Expected fileDoesNotExist, got \(error)")
            }
        }
    }

    /// `exists(at:)` is true for directories too — reading one throws an I/O error, not `fileDoesNotExist`.
    func testDataAtThrowsIOErrorForDirectory() throws {
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        XCTAssertThrowsError(try FileManager.default.data(at: tempDir)) { error in
            guard case StorageError.ioError = error else {
                return XCTFail("Expected ioError, got \(error)")
            }
        }
    }

    // MARK: - iCloud URL

    func testUbiquityDocumentsURLThrowsWhenContainerUnavailable() {
        XCTAssertThrowsError(
            try FileManager.default.ubiquityDocumentsURL(containerURLProvider: { _ in nil })
        ) { error in
            guard case DestinationError.urlNotFound = error else {
                return XCTFail("Expected urlNotFound, got \(error)")
            }
        }
    }

    func testUbiquityDocumentsURLAppendsDocumentsFolder() throws {
        let url = try FileManager.default.ubiquityDocumentsURL(
            folderName: "Documents",
            containerURLProvider: { _ in URL(fileURLWithPath: "/tmp/fake-icloud") }
        )
        XCTAssertEqual(url.path, "/tmp/fake-icloud/Documents")
    }

    // MARK: - ensureDirectory failure

    /// A file blocking an intermediate path component makes `createDirectory` fail.
    func testEnsureDirectoryThrowsWhenBlockedByFile() throws {
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let blocker = tempDir.appendingPathComponent("blocker")
        try Data("x".utf8).write(to: blocker)
        let blockedFileURL = blocker.appendingPathComponent("nested/file.json")
        XCTAssertThrowsError(try FileManager.default.ensureDirectory(at: blockedFileURL)) { error in
            guard case StorageError.directoryCreationFailed = error else {
                return XCTFail("Expected directoryCreationFailed, got \(error)")
            }
        }
    }
}
