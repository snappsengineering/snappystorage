//
//  Service.swift
//  snappystorage
//
//  Created by snapps engineering ltd.
//

import Foundation

protocol Servicable {
    associatedtype T: Storable
    
    var collection: Set<T> { get set }
    
    func refreshCollection() -> Set<T>
    func fetch(with fetchID: String) -> T?
    func save(_ objectToSave: T)
    func save(_ objectsToSave: Set<T>)
    func delete(_ objectToDelete: T)
}

open class Service<T: Storable>: Servicable {

    private var storage: Storage<T>
    private var cloud: Storage<T>?
    private var isICloudEnabled: Bool

    public var collection: Set<T>
    
    public init(destination: Destination<T> = .local(.documentDirectory)) {
        self.storage = Storage<T>(destination: destination)
        self.collection = storage.fetch()
    }
    
    public func refreshCollection() -> Set<T> {
        return collection
    }
    
    func fetch(with fetchID: String) -> T? {
        return collection.filter { $0.id == fetchID }.first
    }
    
    open func save(_ objectToSave: T) {
        saveAndReplaceIfNeeded(objectToSave)
        update()
    }
    
    open func save(_ objectsToSave: Set<T>) {
        objectsToSave.forEach { saveAndReplaceIfNeeded($0) }
        update()
    }
    
    open func delete(_ objectToDelete: T) {
        collection.remove(objectToDelete)
        update()
    }
    
    func saveAndReplaceIfNeeded(_ objectToSave: T) {
        collection.update(with: objectToSave)
    }
    
    func update() {
        self.storage.store(collection: self.collection)
        self.collection = self.storage.fetch()
    }
    
    // MARK: iCloud
    
    public func fetchFromiCloud(callBack: @escaping () -> Void) {
        guard isICloudEnabled, let cloud else { return }
        let cloudCollection = cloud.fetch()
        
        if collection.isEmpty {
            save(cloudCollection)
        }
        callBack()
    }
}
