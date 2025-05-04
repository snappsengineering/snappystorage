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
    
    func refreshCollection() -> [T]
    func fetch(with fetchID: String) -> T?
    func save(_ objectToSave: T)
    func save(_ objectsToSave: [T])
    func delete(_ objectToDelete: T)
}

open class Service<T: StoredObject>: Servicable {
    
    private var storage: Storage<T>
    private var cloud: Storage<T>?
    private var isICloudEnabled: Bool
    
    public var collection: [T] = []
    
    public init(isICloudEnabled: Bool = false) {
        self.storage = Storage<T>(type: .local)
        self.isICloudEnabled = isICloudEnabled
        
        guard isICloudEnabled else { return }
        self.cloud = Storage<T>(type: .cloud)
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
        
        guard isICloudEnabled, let cloud else { return }
        cloud.store(collection: collection)
    }
    
    // MARK: iCloud
    
    public func fetchFromiCloud(callBack: @escaping () -> Void) {
        guard isICloudEnabled, let cloud else { return }
        let cloudCollection = cloud.fetch()
        
        if collection.isEmpty {
            collection = cloudCollection
        }
        callBack()
    }
}
