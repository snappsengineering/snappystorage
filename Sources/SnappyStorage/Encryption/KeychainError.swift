import Foundation

public enum KeychainError: LocalizedError {

    // MARK: - Cases

    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case invalidKeyData

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let status): return "Keychain save failed (\(status))"
        case .loadFailed(let status): return "Keychain load failed (\(status))"
        case .deleteFailed(let status): return "Keychain delete failed (\(status))"
        case .invalidKeyData: return "Keychain item is not a valid encryption key"
        }
    }
}
