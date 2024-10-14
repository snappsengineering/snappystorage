//
//  Crypt.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

import Foundation

final class Crypt {
    
    // MARK: Private Properties
    
    private let aesCrypt: AES
    private let isEnabled: Bool
    private let keyChain: Keychain
    
    // MARK: Initialization

    init(isEnabled: Bool, aesCrypt: AES = AES(), keyChain: Keychain = Keychain()) {
        self.aesCrypt = aesCrypt
        self.isEnabled = isEnabled
        self.keyChain = keyChain
    }
    
    // MARK: Public

    func encrypt(data: Data) throws -> Data {
        guard isEnabled else { return data }
        let aesEncryptedData: Data

        if let (key, iv) = try self.keyChain.aesLocalPair {
            aesEncryptedData = try aesCrypt.encrypt(key: key, iv: iv, payload: data, padding: .aes256)
        } else {
            // Encryption Generation For Keychain
            let key = try aesCrypt.generateValue(blockSize: .aes256)
            let iv = try aesCrypt.generateValue(blockSize: .aes256)
            try self.keyChain.set(key: key, iv: iv)

            aesEncryptedData = try aesCrypt.encrypt(key: key, iv: iv, payload: data, padding: .aes256)
        }

        return aesEncryptedData
    }

    func decrypt(data: Data) throws -> Data {
        guard isEnabled else { return data }
        guard let (key, iv) = try self.keyChain.aesLocalPair else {
            throw CryptError.retrievalFromKeychainFailed
        }

        return try aesCrypt.decrypt(key: key, iv: iv, payload: data, padding: .aes256)
    }
    
    func clearKeychain() throws {
        try self.keyChain.clear()
    }
}
