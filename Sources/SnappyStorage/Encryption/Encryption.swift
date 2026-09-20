import Foundation
import CryptoKit

public struct Encryption: Sendable {

    // MARK: - Properties

    private let key: SymmetricKey

    // MARK: - Lifecycle

    public init(key: SymmetricKey) {
        self.key = key
    }

    public init(keyString: String) {
        let hash = SHA256.hash(data: Data(keyString.utf8))
        self.key = SymmetricKey(data: hash)
    }

    /// Loads an existing key from the keychain or creates and stores a new one.
    public init(keychain store: KeychainKeyStore) throws {
        self.key = try store.loadOrCreate()
    }

    // MARK: - Public

    public static func generateKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    public func encrypt(_ data: Data) throws -> Data {
        let sealed: AES.GCM.SealedBox
        do {
            sealed = try AES.GCM.seal(data, using: key)
        } catch {
            throw EncryptionError.encryptionFailed(error)
        }
        guard let combined = sealed.combined else { throw EncryptionError.invalidData }
        return combined
    }

    public func decrypt(_ data: Data) throws -> Data {
        do {
            let box = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(box, using: key)
        } catch {
            throw EncryptionError.decryptionFailed(error)
        }
    }
}

extension SymmetricKey {

    var dataRepresentation: Data {
        withUnsafeBytes { Data($0) }
    }

    init?(dataRepresentation: Data) {
        guard !dataRepresentation.isEmpty else { return nil }
        self.init(data: dataRepresentation)
    }
}

extension Encryption? {

    func sealedPayload(from data: Data) throws -> Data {
        guard let encryption = self else { return data }
        return try encryption.encrypt(data)
    }

    func openedPayload(from data: Data) throws -> Data {
        guard let encryption = self else { return data }
        return try encryption.decrypt(data)
    }
}
