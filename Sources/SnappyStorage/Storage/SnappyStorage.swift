//
//  SnappyStorage.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

import CommonCrypto
import Foundation

final class SnappyStorage<T: Storable> {
    
    // MARK: File Name
    private let fileName: String = Folder.file.rawValue

    // MARK: Dependencies
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let fileManager: FileManager
    private let snappyCrypt: SnappyCrypt
    
    // MARK: initializer
    
    init(decoder: JSONDecoder, encoder: JSONEncoder, fileManager: FileManager, snappyCrypt: SnappyCrypt) {
        self.decoder = decoder
        self.encoder = encoder
        self.fileManager = fileManager
        self.snappyCrypt = snappyCrypt
    }

    // MARK: File Paths

    var localURL: URL? {
        guard let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last else { return nil }
        let fileURL = directoryURL.appendingPathComponent(fileName)
        return fileURL
    }
    
    var cloudURL: URL? {
        guard let cloudURL = fileManager.url(forUbiquityContainerIdentifier: nil) else { return nil }
        let documentsURL = cloudURL.appendingPathComponent(Folder.documents.rawValue)
        let fileURL = documentsURL.appendingPathComponent(fileName)
        return fileURL
    }
    
    // MARK: Save/Load
    
    // TODO: Manage iCloud save/fetch vs Local save/fetch
    // TODO: Add Encrypt/Decrypt step
    // TODO: Add Mock object
    // TODO: Add ability to save files, images, and videos
    // TODO: Testing!!!
    
    func fetch() async throws -> [T] {
        let localResults = try await load(url: localURL)
        if localResults.isEmpty {
            let cloudResults = try await load(url: cloudURL)
            guard !cloudResults.isEmpty else { throw SnappyError.emptyDataError }
            return cloudResults
        }
        return localResults
    }
    
    func update(from: URL?, to: URL?) async throws {
        let fromElements = try await load(url: from)
        let toElements = try await load(url: to)
        
        try await save(collection: toElements, url: from)
    }
    
    // MARK: Private
    
    private func load(url: URL?) async throws -> [T] {
        guard let fileURL = url else { throw SnappyError.fileNotFound }
        guard fileManager.fileExists(atPath: fileURL.path) else { throw SnappyError.fileNotFound }
        let results = try decoder.decode([T].self, from: Data(contentsOf: fileURL))
        return results
    }
    
    private func save(element: T, url: URL?) async throws {
        guard let fileURL = url else { throw SnappyError.fileNotFound }
        try await createDirectoryIfNotExist(at: fileURL.deletingLastPathComponent())
        try encoder.encode(element).write(to: fileURL)
    }
    
    private func save(collection: [T], url: URL?) async throws {
        guard let fileURL = url else { throw SnappyError.fileNotFound }
        try await createDirectoryIfNotExist(at: fileURL.deletingLastPathComponent())
        try encoder.encode(collection).write(to: fileURL, options: .atomic)
    }

    private func createDirectoryIfNotExist(at url: URL) async throws {
        guard !fileManager.fileExists(atPath: url.path) else { throw SnappyError.invalidOperationError }
        return try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    }
    
    // MARK: Constants
    
    enum Folder {
        case documents
        case file

        var rawValue: String {
            switch self {
            case .documents: return "Documents"
            case .file: return "\(T.self).json"
            }
        }
    }
}
