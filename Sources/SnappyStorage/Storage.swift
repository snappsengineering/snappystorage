//
//  Storage.swift
//  snappystorage
//
//  Created by snapps engineering ltd.
//

import Foundation

public enum StorageType: String {
    case local
    case cloud
}

public class Storage<T: Storable> {
    
    let storageType: StorageType
    
    init(type: StorageType = .local) {
        self.storageType = type
    }
    
    func fetch() -> [T] {
        guard let fileURL = getFilePath() else { return [] }
        return fetchFrom(fileURL: fileURL) ?? []
    }

    func store(collection: [T]) {
        guard let fileURL = getFilePath() else { return }
        writeTo(fileURL: fileURL, collection: collection)
    }
    
    func fetchFrom(fileURL: URL) -> [T]? {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let jsonDecoder = JSONDecoder()
        do {
            let jsonData = try Data(contentsOf: fileURL)
            return try jsonDecoder.decode([T].self, from: jsonData)
        } catch {
            print("Error decoding data: \(error.localizedDescription)")
            return nil
        }
    }
    
    func writeTo(fileURL: URL, collection: [T]) {
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(collection)
            try jsonData.write(to: fileURL, options: .atomic)
        } catch {
            print("Error writing data: \(error.localizedDescription)")
        }
    }
    
    func getFilePath() -> URL? {
        let fileManager = FileManager.default
        
        let storeURL: URL?
        
        switch self.storageType {
        case .local:
            storeURL = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        case .cloud:
            storeURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
        }
        
        return storeURL?.appendingPathComponent(fileName)
    }
    
    var fileName: String {
        return "\(T.self)"
    }
}
