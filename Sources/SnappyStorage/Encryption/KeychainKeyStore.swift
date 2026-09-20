import CryptoKit
import Foundation
import Security

protocol KeychainBackend: Sendable {
    func add(_ query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    func copyMatching(_ query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus
    func delete(_ query: CFDictionary) -> OSStatus
}

struct SecItemKeychainBackend: KeychainBackend, Sendable {
    func add(_ query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        SecItemAdd(query, result)
    }

    func copyMatching(_ query: CFDictionary, result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
        SecItemCopyMatching(query, result)
    }

    func delete(_ query: CFDictionary) -> OSStatus {
        SecItemDelete(query)
    }
}

public struct KeychainKeyStore: Sendable {

    public let service: String
    public let account: String

    private let backend: KeychainBackend

    public init(service: String, account: String = "snappystorage.encryptionKey") {
        self.init(service: service, account: account, backend: SecItemKeychainBackend())
    }

    init(service: String, account: String, backend: KeychainBackend) {
        self.service = service
        self.account = account
        self.backend = backend
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

        let deleteStatus = backend.delete(query as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            throw KeychainError.deleteFailed(deleteStatus)
        }

        let addStatus = backend.add(query as CFDictionary, result: nil)
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
        let status = backend.copyMatching(query as CFDictionary, result: &result)
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
        let status = backend.delete(baseQuery() as CFDictionary)
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
