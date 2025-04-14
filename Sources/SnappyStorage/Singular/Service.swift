//
//  Service.swift
//  snappystorage
//
//  Created by snapps engineering ltd.
//

import Combine
import Foundation

protocol Servicable {
    associatedtype T: Storable
    
    var collection: Set<T> { get set }
    
    func load()
    func fetch(for id: ObjectID) -> Set<T>
    func fetch(for keys: [ObjectID]) -> Set<T>
    func save(_ objectToSave: T)
    func save(_ objectsToSave: Set<T>)
    func delete(_ objectToDelete: T)
    func delete(_ objectsToDelete: Set<T>)
}

open class Service<T: Storable>: Servicable {
    @Published public var collection: Set<T> = []
    
    private var storage: Storage<T>
    private var cancellables = Set<AnyCancellable>()
    
    public init(destination: Destination<T> = .local(.documentDirectory)) {
        self.storage = Storage<T>(destination: destination)
    }

    open func load() {
        self.collection = storage.fetch()
    }
    
    open func fetch(for id: ObjectID) -> Set<T> {
        return collection.filter({ $0.id == id })
    }
    
    open func fetch(for keys: [ObjectID]) -> Set<T> {
        return Set(keys.flatMap { fetch(for: $0) })
    }
    
    open func save(_ objectToSave: T) {
        collection.update(with: objectToSave)
        storage.store(collection: self.collection)
    }
    
    open func save(_ objectsToSave: Set<T>) {
        objectsToSave.forEach { collection.update(with: $0) }
        storage.store(collection: self.collection)
    }
    
    open func delete(_ objectToDelete: T) {
        collection.remove(objectToDelete)
        storage.store(collection: self.collection)
    }
    
    open func delete(_ objectsToDelete: Set<T>) {
        objectsToDelete.forEach { collection.remove($0) }
        storage.store(collection: self.collection)
    }
}
