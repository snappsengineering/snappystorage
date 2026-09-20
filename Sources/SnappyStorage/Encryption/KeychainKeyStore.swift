import CryptoKit
import Foundation
import Security

public struct KeychainKeyStore: Sendable {

    public let service: String
    public let account: String

    public init(service: String, account: String = "snappystorage.encryptionKey") {
        self.service = service
        self.account = account
    }

    public static func forApp(
        bundleIdentifier: String,
        account: String = "snappystorage.encryptionKey"
    ) -> KeychainKeyStore {
        KeychainKeyStore(service: bundleIdentifier, account: account)
    }

    @discardableResult
    public func save(_ key: SymmetricKey) throws -> SymmetricKey {
        var query = baseQuery()
        query[kSecValueData as String] = key.dataRepresentation
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let deleteStatus = SecItemDelete(query as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            throw KeychainError.deleteFailed(deleteStatus)
        }

        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError.saveFailed(addStatus)
        }
        return key
    }

    public func load() throws -> SymmetricKey? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.loadFailed(status)
        }
        guard let key = SymmetricKey(dataRepresentation: data) else {
            throw KeychainError.invalidKeyData
        }
        return key
    }

    public func delete() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    public func loadOrCreate() throws -> SymmetricKey {
        if let key = try load() { return key }
        return try save(Encryption.generateKey())
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
