import CryptoKit
import Security
import XCTest
@testable import SnappyStorage

final class KeychainKeyStoreTests: XCTestCase {

    // MARK: - Properties

    private var store: KeychainKeyStore!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        store = KeychainKeyStore(
            service: "com.snapps.snappystorage.tests",
            account: "key-\(UUID().uuidString)"
        )
        try? store.delete()
    }

    override func tearDown() {
        try? store?.delete()
        super.tearDown()
    }

    // MARK: - Tests

    func testSaveLoadRoundTrip() throws {
        let key = Encryption.generateKey()
        try store.save(key)
        let loaded = try XCTUnwrap(try store.load())
        XCTAssertEqual(keyData(key), keyData(loaded))
    }

    func testLoadOrCreateCreatesOnce() throws {
        let first = try store.loadOrCreate()
        let second = try store.loadOrCreate()
        XCTAssertEqual(keyData(first), keyData(second))
    }

    func testEncryptionKeychainInit() throws {
        let encryption = try Encryption(keychain: store)
        let data = Data("keychain".utf8)
        let encrypted = try encryption.encrypt(data)
        let again = try Encryption(keychain: store)
        XCTAssertEqual(try again.decrypt(encrypted), data)
    }

    func testDeleteRemovesKey() throws {
        _ = try store.loadOrCreate()
        try store.delete()
        XCTAssertNil(try store.load())
    }

    func testDeleteIsIdempotentWhenNothingStored() throws {
        // Nothing saved yet (setUp already deletes) — deleting again must not throw.
        XCTAssertNoThrow(try store.delete())
    }

    func testForAppFactory() {
        let store = KeychainKeyStore.forApp(bundleIdentifier: "com.snapps.test")
        XCTAssertEqual(store.service, "com.snapps.test")
        XCTAssertEqual(store.account, "snappystorage.encryptionKey")
    }

    func testSaveFailedWhenAddFails() {
        let backend = FakeKeychainBackend(
            deleteStatus: errSecSuccess,
            addStatus: errSecDuplicateItem
        )
        let store = KeychainKeyStore(service: "test", account: "acct", backend: backend)
        XCTAssertThrowsError(try store.save(Encryption.generateKey())) { error in
            guard case KeychainError.saveFailed = error else {
                return XCTFail("Expected saveFailed, got \(error)")
            }
        }
    }

    func testLoadFailedWhenCopyMatchingFails() {
        let backend = FakeKeychainBackend(copyMatchingStatus: errSecAuthFailed)
        let store = KeychainKeyStore(service: "test", account: "acct", backend: backend)
        XCTAssertThrowsError(try store.load()) { error in
            guard case KeychainError.loadFailed = error else {
                return XCTFail("Expected loadFailed, got \(error)")
            }
        }
    }

    func testDeleteFailedOnExplicitDelete() {
        let backend = FakeKeychainBackend(deleteStatus: errSecAuthFailed)
        let store = KeychainKeyStore(service: "test", account: "acct", backend: backend)
        XCTAssertThrowsError(try store.delete()) { error in
            guard case KeychainError.deleteFailed = error else {
                return XCTFail("Expected deleteFailed, got \(error)")
            }
        }
    }

    func testDeleteFailedDuringSavePreDelete() {
        let backend = FakeKeychainBackend(deleteStatus: errSecAuthFailed)
        let store = KeychainKeyStore(service: "test", account: "acct", backend: backend)
        XCTAssertThrowsError(try store.save(Encryption.generateKey())) { error in
            guard case KeychainError.deleteFailed = error else {
                return XCTFail("Expected deleteFailed, got \(error)")
            }
        }
    }

    func testInvalidKeyDataWhenStoredBytesAreEmpty() {
        let backend = FakeKeychainBackend(
            copyMatchingStatus: errSecSuccess,
            copyMatchingData: Data()
        )
        let store = KeychainKeyStore(service: "test", account: "acct", backend: backend)
        XCTAssertThrowsError(try store.load()) { error in
            guard case KeychainError.invalidKeyData = error else {
                return XCTFail("Expected invalidKeyData, got \(error)")
            }
        }
    }

    // MARK: - Helpers

    private func keyData(_ key: SymmetricKey) -> Data {
        key.withUnsafeBytes { Data($0) }
    }
}

// MARK: - Fake keychain backend

private struct FakeKeychainBackend: KeychainBackend, Sendable {
    var deleteStatus: OSStatus = errSecSuccess
    var addStatus: OSStatus = errSecSuccess
    var copyMatchingStatus: OSStatus = errSecItemNotFound
    var copyMatchingData: Data?

    func add(_ query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        addStatus
    }

    func copyMatching(_ query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        if copyMatchingStatus == errSecSuccess, let copyMatchingData {
            result?.pointee = copyMatchingData as CFTypeRef
        }
        return copyMatchingStatus
    }

    func delete(_ query: CFDictionary) -> OSStatus {
        deleteStatus
    }
}
