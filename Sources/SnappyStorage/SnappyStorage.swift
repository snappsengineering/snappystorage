//
//  SnappyStorage.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

import Foundation

// MARK: - Storable Protocol
protocol Storable: Equatable & Codable {}

struct SnappyStorage<T: Storable> {
    
    // MARK: File Name
    private let fileName: String = Folder.file.rawValue

    // MARK: Dependencies
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: File Paths

    var SnappyFilePath: URL? {
        guard let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last else { return nil }
        let fileURL = directoryURL.appendingPathComponent(fileName)
        return fileURL
    }
    
    var backupFilePath: URL? {
        guard let backupURL = fileManager.url(forUbiquityContainerIdentifier: nil) else { return nil }
        let documentsURL = backupURL.appendingPathComponent(Folder.documents.rawValue)
        let fileURL = backupURL.appendingPathComponent(fileName)
        return fileURL
    }

    private func createDirectoryIfNotExist(at url: URL) async throws {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        return try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    }
    
    // MARK: Save/Load

    func load() async throws -> T {
        guard let fileURL = SnappyFilePath else { throw StorageError.fileNotFound }
        guard fileManager.fileExists(atPath: fileURL.path) else { throw StorageError.fileNotFound }
        return try decoder.decode(T.self, from: Data(contentsOf: fileURL))
    }
    
    func save(element: T) async throws {
        guard let fileURL = SnappyFilePath else { throw StorageError.fileNotFound }
        try await createDirectoryIfNotExist(at: fileURL.deletingLastPathComponent())
        try encoder.encode(element).write(to: fileURL)
    }
    
    // MARK: Constants
    
    enum StorageError: Error {
        case fileNotFound
    }
    
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
