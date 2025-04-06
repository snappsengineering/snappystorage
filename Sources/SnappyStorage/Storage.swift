//
//  Storage.swift
//  snappystorage
//
//  Created by snapps engineering ltd.
//

import Foundation

class Storage<T: Storable> {
    func fetch() -> [T] {
        guard let fileURL = getFilePath() else { return [] }
        return fetchFrom(fileURL: fileURL) ?? []
    }

    func store(collection: [T]) {
        guard let fileURL = getFilePath() else { return }
        writeTo(fileURL: fileURL, collection: collection)
    }
    
    private func fetchFrom(fileURL: URL) -> [T]? {
        let jsonDecoder = JSONDecoder()
        do {
            if let jsonData = try? Data(contentsOf: fileURL) {
                return try jsonDecoder.decode([T].self, from: jsonData)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        return nil
    }
    
    private func writeTo(fileURL: URL, collection: [T]) {
        let jsonEncoder = JSONEncoder()
        do {
            let jsonData = try jsonEncoder.encode(collection)
            try jsonData.write(to: fileURL, options: .atomic)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    private func getFilePath() -> URL? {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let applicationSupportURL = urls.last else { return nil }
        do {
            try fileManager.createDirectory(at: applicationSupportURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error)
        }
        return applicationSupportURL.appendingPathComponent(fileName)
    }
    
    private var fileName: String {
        return "\(T.self)"
    }
}
