//
//  AESCrypt.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

import CommonCrypto
import Foundation

final class AESCrypt {
    
    // MARK: Public Functions

    func encrypt(key: String, iv: String, payload: Data, padding: CryptPadding) throws -> Data {
        return try operation(with: .encrypt, key: key, iv: iv, payload: payload, padding: padding)
    }

    func decrypt(key: String, iv: String, payload: Data, padding: CryptPadding) throws -> Data {
        return try operation(with: .decrypt, key: key, iv: iv, payload: payload, padding: padding)
    }

    func base64ToData(base64String: String) throws -> Data {
        guard let base64decoded = Data(base64Encoded: base64String, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters) else {
            throw CryptError.byteConversionFailed
        }
        return base64decoded
    }

    func generateValue(blockSize: CryptPadding) throws -> String {
        var bytes = [UInt8](repeating: 0, count: blockSize.rawValue)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        guard result == errSecSuccess else {
            throw CryptError.generateValueFailed
        }

        return Data(bytes).base64EncodedString()
    }
    
    // MARK: Private Functions

    private func operation(with type: CryptOperation, key: String, iv: String, payload: Data, padding: CryptPadding) throws -> Data {
        let keyBytes = Array(try base64ToData(base64String: key))
        let ivBytes = Array(try base64ToData(base64String: iv))
        let payloadBytes = Array(payload)

        var outLength = Int(0)
        var outBytes = [UInt8](repeating: 0, count: payload.count + padding.rawValue)

        let status: CCCryptorStatus = CCCrypt(
            type.rawValue,
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            keyBytes,
            keyBytes.count,
            ivBytes,
            payloadBytes,
            payloadBytes.count,
            &outBytes,
            outBytes.count,
            &outLength
        )

        guard status == kCCSuccess else {
            throw CryptError.operationFailed(status: status)
        }

        return Data(bytes: &outBytes, count: outLength)
    }
}

// MARK: - Enums

enum CryptError: Error {
    case byteConversionFailed
    case generateValueFailed
    case operationFailed(status: CCCryptorStatus)
    case retrievalFromKeychainFailed
}

enum CryptOperation {
    case decrypt
    case encrypt

    var rawValue: UInt32 {
        switch self {
        case .decrypt:
            return CCOperation(kCCDecrypt)
        case .encrypt:
            return CCOperation(kCCEncrypt)
        }
    }
}

enum CryptPadding {
    case aes128
    case aes256

    var rawValue: Int {
        switch self {
        case .aes128:
            return kCCKeySizeAES128
        case .aes256:
            return kCCKeySizeAES256
        }
    }
}
