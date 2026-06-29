import CryptoKit
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

    // MARK: - Helpers

    private func keyData(_ key: SymmetricKey) -> Data {
        key.withUnsafeBytes { Data($0) }
    }
}
