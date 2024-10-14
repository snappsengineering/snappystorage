//
//  StoredObjectService.swift
//  retoxifier (iOS)
//
//  Created by Shane Noormohamed on 12/25/23.
//

import Foundation

protocol ServiceProtocol {
    associatedtype T
    
    func load() async throws
    func fetch(with fetchID: String) async throws -> T
    func save(_ object: T) async throws
    func save(_ objects: [T]) async throws
    func delete(_ object: T)  async throws
}

class Service<T: StoredObject>: ServiceProtocol {
    
    private var storage: Storage<T>
    private var storedObjects: [T] = []
    
    init(storage: Storage<T>) {
        self.storage = storage
    }

    // load asynchronously from storage
    func load() async throws {
        storedObjects = try await storage.load()
    }
    
    func fetch(with fetchID: String) async throws -> T {
        try await load()
        guard let item = storedObjects.filter({ $0.objectID == fetchID }).first else { throw SnappyError.dataNotFound }
        return item
    }
    
    func save(_ object: T) async throws {
        updateStorage(with: object)
        try await commit()
    }
    
    func save(_ objects: [T]) async throws {
        for object in objects {
            updateStorage(with: object)
        }
        try await commit()
    }
    
    func delete(_ object: T) async throws {
        storedObjects.removeAll(where: { $0 == object })
        try await commit()
    }
    
    func commit() async throws {
        try await storage.save(collection: storedObjects)
    }
    
    private func updateStorage(with object: T) {
        if let index = storedObjects.firstIndex(where: { $0 == object }) {
            storedObjects[index] = object
        } else {
            storedObjects.append(object)
        }
    }
 }
