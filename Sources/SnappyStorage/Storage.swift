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
    
    var location: Location<T>
    
    init(
        jsonDecoder: JSONDecoder = JSONDecoder(),
        jsonEncoder: JSONEncoder = JSONEncoder(),
        location: Location<T>
    ) {
        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder
        self.location = location
    }
    
    func store(collection: [T]) {
        
        guard let fileURL = location.url
        else { return }
        
        writeTo(fileURL: fileURL, collection: collection)
    }
    
    func fetch() -> [T] {

        guard location.fileExists,
              let fileURL = location.url
        else { return [] }

        do {
            let jsonData = try Data(contentsOf: fileURL)
            return try jsonDecoder.decode([T].self, from: jsonData)
        } catch {
            print("Error decoding data: \(error.localizedDescription)")
            return []
        }

    }
    
    func writeTo(fileURL: URL, collection: [T]) {
        do {
            let jsonData = try jsonEncoder.encode(collection)
            try jsonData.write(to: fileURL, options: .atomic)
        } catch {
            print("Error writing data: \(error.localizedDescription)")
        }
    }
}
