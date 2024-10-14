//
//  Location.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

import Foundation

final class Location<T: Storable> {
    
    // MARK: Private properties
    
    private let fileManager: FileManager
    private let fileName: String = Folder.file.rawValue

    // MARK: Public properties
    
    let destination: Destination
    var url: URL?
    
    // MARK: Public computed properties
    
    var lastUpdated: Date? {
        get throws {
            guard let path = url?.path else { return nil }
            return try fileManager.attributesOfItem(atPath: path)[.modificationDate] as? Date
        }
    }
    
    var fileExists: Bool {
        guard let path = url?.path else { return false }
        return fileManager.fileExists(atPath: path)
    }
    
    // MARK: init
    
    init(destination: Destination, fileManager: FileManager) {
        self.destination = destination
        self.fileManager = fileManager
        self.url = makeURL(for: destination)
    }
    
    // MARK: Public
    
    func createDirectoryIfNotExist() async throws {
        guard let url = url,
              !fileExists else { throw SnappyError.invalidOperationError }
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    }
    
    func removeDirectory() async throws {
        guard let url = url,
              !fileExists else { throw SnappyError.invalidOperationError }
        try fileManager.removeItem(at: url)
    }
    
    // MARK: Private
    
    private func makeURL(for destination: Destination) -> URL? {
        var locationURL: URL?

        switch destination {
        case .local:
            guard let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last else { return nil }
            locationURL = directoryURL
        case .cloud:
            guard let cloudURL = fileManager.url(forUbiquityContainerIdentifier: nil) else { return nil }
            let documentsURL = cloudURL.appendingPathComponent(Folder.documents.rawValue)
            locationURL = documentsURL
        }
        
        let fileURL = locationURL?.appendingPathComponent(fileName)
        return fileURL
    }
    
    // MARK: Enums
    
    enum Destination {
        case local
        case cloud
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
