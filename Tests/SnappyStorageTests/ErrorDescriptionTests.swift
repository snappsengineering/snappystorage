import XCTest
@testable import SnappyStorage

final class ErrorDescriptionTests: XCTestCase {

    // MARK: - StorageError

    func testStorageErrorDescriptions() {
        XCTAssertEqual(StorageError.fileDoesNotExist.errorDescription, "Storage file does not exist")
        XCTAssertEqual(
            StorageError.directoryCreationFailed("/tmp/x").errorDescription,
            "Failed to create directory: /tmp/x"
        )
        XCTAssertNotNil(StorageError.ioError(EncoderError.encodingFailed(NSError(domain: "t", code: 1))).errorDescription)
    }

    // MARK: - EncryptionError

    func testEncryptionErrorDescriptions() {
        let underlying = NSError(domain: "t", code: 1)
        XCTAssertNotNil(EncryptionError.encryptionFailed(underlying).errorDescription)
        XCTAssertNotNil(EncryptionError.decryptionFailed(underlying).errorDescription)
        XCTAssertEqual(EncryptionError.invalidData.errorDescription, "Invalid encrypted data")
    }

    // MARK: - KeychainError

    func testKeychainErrorDescriptions() {
        XCTAssertNotNil(KeychainError.saveFailed(-1).errorDescription)
        XCTAssertNotNil(KeychainError.loadFailed(-1).errorDescription)
        XCTAssertNotNil(KeychainError.deleteFailed(-1).errorDescription)
        XCTAssertEqual(KeychainError.invalidKeyData.errorDescription, "Keychain item is not a valid encryption key")
    }

    // MARK: - EncoderError

    func testEncoderErrorDescriptions() {
        let underlying = NSError(domain: "t", code: 1)
        XCTAssertNotNil(EncoderError.encodingFailed(underlying).errorDescription)
        XCTAssertNotNil(EncoderError.decodingFailed(underlying).errorDescription)
    }

    // MARK: - DestinationError

    func testDestinationErrorDescription() {
        XCTAssertNotNil(DestinationError.urlNotFound("detail").errorDescription)
    }

    // MARK: - JSON coding failure paths

    func testEncodePayloadWrapsEncodingFailure() {
        struct NotEncodable: Encodable {
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                // NaN with the default (throwing) float strategy fails JSONEncoder.encode.
                try container.encode(Double.nan)
            }
        }
        XCTAssertThrowsError(try JSONEncoder().encodePayload(NotEncodable())) { error in
            guard case EncoderError.encodingFailed = error else {
                return XCTFail("Expected encodingFailed, got \(error)")
            }
        }
    }
}
