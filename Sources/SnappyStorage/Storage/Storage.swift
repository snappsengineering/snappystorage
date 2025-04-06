//
//  Storage.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

import Foundation

final public class Storage<T: Storable> {

    // MARK: Public Properties
    
    var location: Location<T>
    
    // MARK: Private Properties

    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // MARK: init
    
    init(location: Location<T>, decoder: JSONDecoder = JSONDecoder(), encoder: JSONEncoder = JSONEncoder()) {
        self.location = location
        self.decoder = decoder
        self.encoder = encoder
    }
    
    // MARK: Save/Load
    
    // MARK: Public functions
    
    func load() async throws -> [T] {
        guard let url = location.url else { throw SnappyError.fileNotFound }
        guard location.fileExists else { throw SnappyError.fileNotFound }
        let data = try Data(contentsOf: url)
        let results = try decoder.decode([T].self, from: data)
        guard !results.isEmpty else { throw SnappyError.emptyDataError }
        return results
    }
    
    func save(element: T) async throws {
        guard location.fileExists else {
            try await location.createDirectoryIfNotExist()
            return
        }
        let encodedElement = try encoder.encode(element)
        try await write(data: encodedElement)
    }
    
    func save(collection: [T]) async throws {
        guard location.fileExists else {
            try await location.createDirectoryIfNotExist()
            return
        }
        let encodedCollection = try encoder.encode(collection)
        try await write(data: encodedCollection)
    }
    
    // MARK: Private functions
    
    private func write(data: Data) async throws {
        guard let url = location.url else { throw SnappyError.fileNotFound }
        try data.write(to: url, options: .atomic)
    }
}
