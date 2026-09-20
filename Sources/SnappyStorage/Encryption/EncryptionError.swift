import Foundation

public enum EncryptionError: LocalizedError {

    // MARK: - Cases

    case encryptionFailed(Error)
    case decryptionFailed(Error)
    case invalidData

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .encryptionFailed(let e): return "Encryption failed: \(e.localizedDescription)"
        case .decryptionFailed(let e): return "Decryption failed: \(e.localizedDescription)"
        case .invalidData: return "Invalid encrypted data"
        }
    }
}
