//
//  Storage.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

import CommonCrypto
import Foundation

final class Storage<T: Storable> {

    // MARK: Public Properties
    
    var location: Location<T>
    
    // MARK: Private Properties

    private let crypt: Crypt
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // MARK: init
    
    init(crypt: Crypt, location: Location<T>, decoder: JSONDecoder = JSONDecoder(), encoder: JSONEncoder = JSONEncoder()) {
        self.location = location
        self.crypt = crypt
        self.decoder = decoder
        self.encoder = encoder
    }
    
    // MARK: Save/Load

    // TODO: Add Mock object
    // TODO: Add ability to save files, images, and videos
    // TODO: Testing!!!
    
    // MARK: Public functions
    
    func load() async throws -> [T] {
        guard let url = location.url else { throw SnappyError.fileNotFound }
        guard location.fileExists else { throw SnappyError.fileNotFound }
        let data = try Data(contentsOf: url)
        let decryptedResults = try await decryptedRead(data: data)
        let results = try decoder.decode([T].self, from: decryptedResults)
        guard !results.isEmpty else { throw SnappyError.emptyDataError }
        return results
    }
    
    func save(element: T) async throws {
        guard location.fileExists else {
            try await location.createDirectoryIfNotExist()
            return
        }
        let encodedElement = try encoder.encode(element)
        try await encryptedWrite(data: encodedElement)
    }
    
    func save(collection: [T]) async throws {
        guard location.fileExists else {
            try await location.createDirectoryIfNotExist()
            return
        }
        let encodedCollection = try encoder.encode(collection)
        try await encryptedWrite(data: encodedCollection)
    }
    
    // MARK: Private functions
    
    private func decryptedRead(data: Data) async throws -> Data {
        return try crypt.decrypt(data: data)
    }
    
    private func encryptedWrite(data: Data) async throws {
        guard let url = location.url else { throw SnappyError.fileNotFound }
        let encryptedData = try crypt.encrypt(data: data)
        try encryptedData.write(to: url, options: .atomic)
    }
}
