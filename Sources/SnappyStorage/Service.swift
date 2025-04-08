//
//  Service.swift
//  snappystorage
//
//  Created by snapps engineering ltd.
//

import Foundation

protocol Servicable {
    associatedtype T
    
    var collection: [T] { get set }
    
    func refreshCollection() -> [T]
    func fetch(with fetchID: String) -> T?
    func save(_ objectToSave: T)
    func save(_ objectsToSave: [T])
    func delete(_ objectToDelete: T)
}

open class Service<T: StoredObject>: Servicable {

    private var storage: Storage<T>
    
    public var collection: [T]
    
    public init() {
        self.storage = Storage<T>(destination: .local(.documentDirectory))
        self.collection = storage.fetch()
    }
    
    public func refreshCollection() -> [T] {
        return collection
    }
    
    func fetch(with fetchID: String) -> T? {
        return collection.filter { $0.objectID == fetchID }.first
    }
    
    public func save(_ objectToSave: T) {
        saveAndReplaceIfNeeded(objectToSave)
        update()
    }
    
    public func save(_ objectsToSave: [T]) {
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
    
    public func delete(_ objectToDelete: T) {
        collection.removeAll(where: { $0 == objectToDelete })
        update()
    }
    
    func update() {
        self.storage.store(collection: self.collection)
        self.collection = self.storage.fetch()
    }
}
