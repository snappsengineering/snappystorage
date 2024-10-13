//
//  StoredObjectService.swift
//  retoxifier (iOS)
//
//  Created by Shane Noormohamed on 12/25/23.
//

import Foundation

protocol ServiceProtocol {
    associatedtype T
    
    var storedObjects: [T] { get set }
    
    func fetchCollection() -> [T]
    func fetch(with fetchID: String) -> T?
    func save(_ objectToSave: T)
    func save(_ objectsToSave: [T])
    func delete(_ objectToDelete: T)
}

class Service<T: StoredObject>: ServiceProtocol {
    
    private var storage: Storage<T>
    var storedObjects: [T] = []
    
    init(storage: Storage<T>) {
        self.storage = storage
    }

    // load asynchronously from storage
    func load() async throws {
        storedObjects = try await storage.fetch()
    }

    func fetchCollection() -> [T] {
        return storedObjects
    }
    
    func fetch(with fetchID: String) -> T? {
        return storedObjects.filter { $0.objectID == fetchID }.first
    }
    
    func save(_ objectToSave: T) {
        saveAndReplaceIfNeeded(objectToSave)
    }
    
    func save(_ objectsToSave: [T]) {
        objectsToSave.forEach { saveAndReplaceIfNeeded($0) }
    }
    
    private func saveAndReplaceIfNeeded(_ objectToSave: T) {
        if let index = storedObjects.firstIndex(where: { $0 == objectToSave }) {
            storedObjects[index] = objectToSave
        } else {
            storedObjects.append(objectToSave)
        }
    }
    
    func delete(_ objectToDelete: T) {
        storedObjects.removeAll(where: { $0 == objectToDelete })
    }
 }
