//
//  Storage.swift
//  snappystorage
//
//  Created by snapps engineering ltd.
//

import Foundation

public class Storage<T: Storable> {
    
    
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let fileManager: FileManager
    
    private var storageURL: URL?
    
    var fileExists: Bool {
        guard let path = storageURL?.path else { return false }
        return fileManager.fileExists(atPath: path)
    }
    
    init(
        jsonDecoder: JSONDecoder = JSONDecoder(),
        jsonEncoder: JSONEncoder = JSONEncoder(),
        fileManager: FileManager = .default,
        destination: Destination<T>
    ) {

        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
        self.fileManager = fileManager

        self.storageURL = destination.makeURL(with: fileManager)

    }

    func store(collection: Set<T>) {
        
        guard let storageURL
        else { return }
        
        do {
            let jsonData = try jsonEncoder.encode(collection)
            try jsonData.write(to: storageURL, options: .atomic)
        } catch {
            print("Error writing data: \(error.localizedDescription)")
        }

    }
    
    func fetch() -> Set<T> {
        
        guard let storageURL,
              fileExists
        else { return [] }
        
        do {
            let jsonData = try Data(contentsOf: storageURL)
            print("File contents:")
            print(String(data: jsonData, encoding: .utf8) ?? "Unable to print file contents")
            return try jsonDecoder.decode(Set<T>.self, from: jsonData)
        } catch {
            print("Error decoding data: \(error.localizedDescription)")
            return []
        }
        
    }
}
