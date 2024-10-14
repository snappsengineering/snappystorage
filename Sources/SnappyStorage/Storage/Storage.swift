//
//  Storage.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

import CommonCrypto
import Foundation

class Storage<T: Storable> {
    
    var location: Location<T>

    // MARK: Dependencies
    private let crypt: Crypt
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let fileManager: FileManager
    
    init(location: Location<T>, crypt: Crypt, decoder: JSONDecoder, encoder: JSONEncoder, fileManager: FileManager) {
        self.location = location
        self.crypt = crypt
        self.decoder = decoder
        self.encoder = encoder
        self.fileManager = fileManager
    }
    
    // MARK: Save/Load
    
    // TODO: Manage iCloud save/fetch vs Local save/fetch
    // TODO: Add Mock object
    // TODO: Add ability to save files, images, and videos
    // TODO: Testing!!!
    
    func load() async throws -> [T] {
        guard let url = location.url else { throw SnappyError.fileNotFound }
        guard fileManager.fileExists(atPath: url.path) else { throw SnappyError.fileNotFound }
        let decryptedResults = try crypt.decrypt(data: Data(contentsOf: url))
        let results = try decoder.decode([T].self, from: decryptedResults)
        guard !results.isEmpty else { throw SnappyError.emptyDataError }
        return results
    }
    
    func save(element: T) async throws {
        guard let url = location.url else { throw SnappyError.fileNotFound }
        guard fileManager.fileExists(atPath: url.path) else {
            try await createDirectoryIfNotExist()
            return
        }
        let encodedElement = try encoder.encode(element)
        let encryptedElement = try crypt.encrypt(data: encodedElement)
        try encodedElement.write(to: url, options: .atomic)
    }
    
    func save(collection: [T]) async throws {
        guard let url = location.url else { throw SnappyError.fileNotFound }
        guard fileManager.fileExists(atPath: url.path) else {
            try await createDirectoryIfNotExist()
            return
        }
        try encoder.encode(collection).write(to: url, options: .atomic)
    }
    
    // MARK: Private

    private func createDirectoryIfNotExist() async throws {
        guard let url = location.url,
              !fileManager.fileExists(atPath: url.path) else { throw SnappyError.invalidOperationError }
        return try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    }
}
