import Foundation
import CryptoKit

public struct Encryption {

    public enum EncryptionError: LocalizedError {
        case keyGenerationFailed
        case encryptionFailed(Error)
        case decryptionFailed(Error)
        case invalidData

        public var errorDescription: String? {
            switch self {
            case .keyGenerationFailed: return "Failed to generate encryption key"
            case .encryptionFailed(let e): return "Encryption failed: \(e.localizedDescription)"
            case .decryptionFailed(let e): return "Decryption failed: \(e.localizedDescription)"
            case .invalidData: return "Invalid encrypted data"
            }
        }
    }

    private let key: SymmetricKey

    public init(key: SymmetricKey) {
        self.key = key
    }

    public init(keyString: String) {
        let hash = SHA256.hash(data: Data(keyString.utf8))
        self.key = SymmetricKey(data: hash)
    }

    public static func generateKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    public func encrypt(_ data: Data) throws -> Data {
        do {
            let sealed = try AES.GCM.seal(data, using: key)
            guard let combined = sealed.combined else { throw EncryptionError.invalidData }
            return combined
        } catch let error as EncryptionError {
            throw error
        } catch {
            throw EncryptionError.encryptionFailed(error)
        }
    }

    public func decrypt(_ data: Data) throws -> Data {
        do {
            let box = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(box, using: key)
        } catch let error as EncryptionError {
            throw error
        } catch {
            throw EncryptionError.decryptionFailed(error)
        }
    }
}
