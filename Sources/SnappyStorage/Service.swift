//
//  Service.swift
//  snappystorage
//
//  Created by Shane Noormohamed on 12/25/23.
//

import Foundation

protocol Servicable {
    associatedtype T
    
    var collection: [T] { get set }
    
    func fetchCollection() -> [T]
    func fetch(with fetchID: String) -> T?
    func save(_ objectToSave: T)
    func save(_ objectsToSave: [T])
    func delete(_ objectToDelete: T)
}

class Service<T: StoredObject>: Servicable {
    
    private var storage: Storage<T>
    
    var collection: [T]
    
    init() {
        self.storage = Storage<T>()
        self.collection = storage.fetch()
    }
    
    func fetchCollection() -> [T] {
        return collection
    }
    
    func fetch(with fetchID: String) -> T? {
        return collection.filter { $0.objectID == fetchID }.first
    }
    
    func save(_ objectToSave: T) {
        saveAndReplaceIfNeeded(objectToSave)
        update()
    }
    
    func save(_ objectsToSave: [T]) {
        objectsToSave.forEach { saveAndReplaceIfNeeded($0) }
        update()
    }
    
    func saveAndReplaceIfNeeded(_ objectToSave: T) {
        if let index = collection.firstIndex(where: { $0 == objectToSave }) {
            collection[index] = objectToSave
        } else {
            collection.append(objectToSave)
        }
    }
    
    func delete(_ objectToDelete: T) {
        collection.removeAll(where: { $0 == objectToDelete })
        update()
    }
    
    func update() {
        self.storage.store(collection: self.collection)
        self.collection = self.storage.fetch()
    }
}
