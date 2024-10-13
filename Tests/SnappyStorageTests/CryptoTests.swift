//
//  CryptoTests.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

import CommonCrypto
import XCTest
@testable import SnappyStorage

class CryptoTests: XCTestCase {
    // Authentic key, iv, and payload from an API request
    private let iv = "avoNvuIkEE2/MD1CbcnSTQ==\n"
    private let key = "S1BYv9GT940b/dB7lLVIYwD+mePOaJ1xNI+UN0bilWY=\n"
    private let encryptedServerSidePayload = "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\n"

    func testInvalidKey() {
        let crypt = AESCrypt()
        let expectedPayload = "Encrypted message for testing"
        do {
            guard let data = expectedPayload.data(using: .utf8) else { return }
            let encryptedPayload = try crypt.encrypt(key: key, iv: iv, payload: data, padding: .aes128)
            let _ = try crypt.decrypt(key: "", iv: iv, payload: encryptedPayload, padding: .aes128)
        }
        catch {
            XCTAssertNotNil(error)
            return
        }
        XCTFail("Decrypt error not thrown")
    }

    func testInvalidIV() {
        let crypt = AESCrypt()
        let expectedPayload = "Encrypted message for testing"
        do {
            guard let data = expectedPayload.data(using: .utf8) else { return }
            let encryptedPayload = try crypt.encrypt(key: key, iv: iv, payload: data, padding: .aes128)
            let _ = try crypt.decrypt(key: key, iv: "", payload: encryptedPayload, padding: .aes128)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDecrypt() {
        let crypt = AESCrypt()
        let expectedPayload = "Encrypted message for testing"
        do {
            guard let data = expectedPayload.data(using: .utf8) else { return }
            let encryptedPayload = try crypt.encrypt(key: key, iv: iv, payload: data, padding: .aes128)
            let decryptedData = try crypt.decrypt(key: key, iv: iv, payload: encryptedPayload, padding: .aes128)
            let decryptedPayload = String(bytes: decryptedData, encoding: .utf8)
            XCTAssertEqual(expectedPayload, decryptedPayload)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDecryptURL() {
        let crypt = AESCrypt()
        let expectedPayload = "https://www.akira.md/terms"
        do {
            guard let data = expectedPayload.data(using: .utf8) else { return }
            let encryptedPayload = try crypt.encrypt(key: key, iv: iv, payload: data, padding: .aes128)
            let decryptedData = try crypt.decrypt(key: key, iv: iv, payload: encryptedPayload, padding: .aes128)
            let decryptedPayload = String(bytes: decryptedData, encoding: .utf8)
            XCTAssertEqual(expectedPayload, decryptedPayload)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDecryptSpecialCharacters() {
        let crypt = AESCrypt()
        let expectedPayload = "\"A test string\"\nwith special characters ✓"
        do {
            guard let data = expectedPayload.data(using: .utf8) else { return }
            let encryptedPayload = try crypt.encrypt(key: key, iv: iv, payload: data, padding: .aes128)
            let decryptedData = try crypt.decrypt(key: key, iv: iv, payload: encryptedPayload, padding: .aes128)
            let decryptedPayload = String(bytes: decryptedData, encoding: .utf8)
            XCTAssertEqual(expectedPayload, decryptedPayload)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDecryptEmoji() {
        let crypt = AESCrypt()
        let expectedPayload = "🍔 A test string 👨🏽‍💻 with emoji 🤯"
        do {
            guard let data = expectedPayload.data(using: .utf8) else { return }
            let encryptedPayload = try crypt.encrypt(key: key, iv: iv, payload: data, padding: .aes128)
            let decryptedData = try crypt.decrypt(key: key, iv: iv, payload: encryptedPayload, padding: .aes128)
            let decryptedPayload = String(bytes: decryptedData, encoding: .utf8)
            XCTAssertEqual(expectedPayload, decryptedPayload)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testDecryptJson() {
        let crypt = AESCrypt()
        let expectedPayload = "👨‍⚕️A server side test 🌡 message with emoji 👩🏼‍⚕️"
        do {
            let payload = try crypt.base64ToData(base64String: encryptedServerSidePayload)
            let decryptedData = try crypt.decrypt(key: key, iv: iv, payload: payload, padding: .aes128)
            guard let string = String(bytes: decryptedData, encoding: .utf8) else {
                XCTFail()
                return
            }

            guard let data = string.data(using: .utf8),
                let messageDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let res = messageDict["res"] as? [String: Any],
                let payload = res["payload"] as? [String: Any],
                let payloadData = payload["data"] as? String
                else {
                    XCTFail()
                    return
            }

            XCTAssertEqual(payloadData, expectedPayload)
        }
        catch {
            XCTFail(error.localizedDescription)
        }
    }
}
