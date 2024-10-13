//
//  SnappyKeychain.swift
//  SnappyStorage
//
//  Created by Shane Noormohamed on 2024-10-12.
//

import Foundation
import Security

final class SnappyKeychain {
    
    var aesLocalPair: (key: String, iv: String)? {
        get throws {
            try (aesLocalKey, aesLocalIV)
        }
    }
    
    // MARK: Private properties

    private var aesLocalKey: String {
        get throws {
            return try fetchAsStringValue(Keys.aesLocalKey)
        }
    }
    
    private var aesLocalIV: String {
        get throws {
            return try fetchAsStringValue(Keys.aesLocalIV)
        }
    }
    
    // MARK: Public
    
    // set aes credentials
    func set(key: String, iv: String) throws {
        let keyData = try key.dataValue
        let ivData = try iv.dataValue
        
        try store(Keys.aesLocalKey, data: keyData)
        try store(Keys.aesLocalIV, data: ivData)
    }
    
    // store keychain item
    func store(_ key: String, data: Data) throws {
        try itemExists(key) ? updateItem(key, data: data) : addItem(key, data: data)
    }
    
    // fetch keychain item as String
    func fetchAsStringValue(_ key: String) throws -> String {
        try fetch(key).stringValue
    }
    
    // delete keychain item
    func delete(_ key: String) throws {
        let status = SecItemDelete([
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ] as CFDictionary)
        
        switch status {
        case errSecSuccess: return
        default: throw SnappyError.keychainError
        }
    }
    
    // delete all keychain items (of generic password type)
    func clear() throws {
        let status = SecItemDelete([
            kSecClass: kSecClassGenericPassword,
        ] as CFDictionary)
        
        try check(status)
    }
    
    // MARK: Private
    
    private func check(_ status: OSStatus) throws {
        guard status == errSecSuccess else { throw SnappyError.keychainError }
    }

    //check if item exists
    private func itemExists(_ key: String) throws -> Bool {
        let status = SecItemCopyMatching([
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true
        ] as CFDictionary, nil)
        
        switch status {
        case errSecSuccess: return true
        case errSecItemNotFound: return false
        default: throw SnappyError.keychainError
        }
    }
    
    // add item to keychain
    private func addItem(_ key: String, data: Data) throws {
        let status = SecItemAdd([
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data
        ] as CFDictionary, nil)

        try check(status)
    }

    // update a keychain item
    private func updateItem(_ key: String, data: Data) throws {
        let status = SecItemUpdate([
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ] as CFDictionary, [
            kSecValueData: data
        ] as CFDictionary)
        
        try check(status)
    }
    
    // fetch keychain item as Data
    private func fetch(_ key: String) throws -> Data {
        var result: AnyObject?
        let status = SecItemCopyMatching([
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true
        ] as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let result = result as? Data else {
            throw SnappyError.keychainError
        }
        
        return result
    }

    // MARK: Constants
    
    struct Keys {
        static let aesLocalKey = "aesLocalKey"
        static let aesLocalIV = "aesLocalIV"
    }
}
