//
//  SnappyStorage.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

import CommonCrypto
import Foundation

// MARK: - Storable Protocol
protocol Storable: Equatable & Codable {}

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
    
    var backupURL: URL? {
        guard let backupURL = fileManager.url(forUbiquityContainerIdentifier: nil) else { return nil }
        let documentsURL = backupURL.appendingPathComponent(Folder.documents.rawValue)
        let fileURL = documentsURL.appendingPathComponent(fileName)
        return fileURL
    }

    private func createDirectoryIfNotExist(at url: URL) async throws {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        return try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    }
    
    // MARK: Save/Load
    
    // TODO: Manage iCloud save/fetch vs Local save/fetch
    // TODO: Add Encrypt/Decrypt step
    // TODO: Add Mock object
    // TODO: Add ability to save files, images, and videos
    // TODO: Testing!!!

    func load() async throws -> T {
        guard let fileURL = localURL else { throw SnappyError.fileNotFound }
        guard fileManager.fileExists(atPath: fileURL.path) else { throw SnappyError.fileNotFound }
        return try decoder.decode(T.self, from: Data(contentsOf: fileURL))
    }
    
    func save(element: T) async throws {
        guard let fileURL = backupURL else { throw SnappyError.fileNotFound }
        try await createDirectoryIfNotExist(at: fileURL.deletingLastPathComponent())
        try encoder.encode(element).write(to: fileURL)
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
