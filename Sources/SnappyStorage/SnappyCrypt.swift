//
//  SnappyCrypt.swift
//  Akira
//
//  Created by Shane Noormohamed on 2023-05-02.
//  Copyright © 2023 TELUS Health Virtual Care. All rights reserved.
//

import Foundation

final class SnappyCrypt {
    private let aesCrypt = AESCrypt()
    private let keyChain: SnappyKeychain
    
    // MARK: Initialization

    init(keyChain: SnappyKeychain) {
        self.keyChain = keyChain
    }
    
    // MARK: Public

    func encrypt(data: Data) throws -> Data {
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
        guard let (key, iv) = try self.keyChain.aesLocalPair else {
            throw CryptError.retrievalFromKeychainFailed
        }

        return try aesCrypt.decrypt(key: key, iv: iv, payload: data, padding: .aes256)
    }
    
    func clearKeychain() throws {
        try self.keyChain.clear()
    }
}
