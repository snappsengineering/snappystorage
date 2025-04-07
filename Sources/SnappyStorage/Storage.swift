//
//  Storage.swift
//  snappystorage
//
//  Created by snapps engineering ltd.
//

import Foundation

public class Storage<T: Storable> {
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
        let storeURL = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return storeURL?.appendingPathComponent(fileName)
    }
    
    var fileName: String {
        return "\(T.self)"
    }
}
