import XCTest
@testable import SnappyStorage

final class EncryptionTests: XCTestCase {

    func testRoundTrip() throws {
        let enc = Encryption(key: Encryption.generateKey())
        let original = Data("Hello, World!".utf8)
        let encrypted = try enc.encrypt(original)
        let decrypted = try enc.decrypt(encrypted)
        XCTAssertEqual(decrypted, original)
        XCTAssertNotEqual(encrypted, original)
    }

    func testKeyStringInit() throws {
        let enc = Encryption(keyString: "my-secret-password")
        let data = Data("test".utf8)
        let encrypted = try enc.encrypt(data)
        let decrypted = try enc.decrypt(encrypted)
        XCTAssertEqual(decrypted, data)
    }

    func testWrongKeyFails() throws {
        let enc1 = Encryption(key: Encryption.generateKey())
        let enc2 = Encryption(key: Encryption.generateKey())
        let encrypted = try enc1.encrypt(Data("secret".utf8))
        XCTAssertThrowsError(try enc2.decrypt(encrypted))
    }
}
