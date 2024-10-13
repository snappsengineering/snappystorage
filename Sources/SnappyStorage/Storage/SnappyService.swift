//
//  StoredObjectService.swift
//  retoxifier (iOS)
//
//  Created by Shane Noormohamed on 12/25/23.
//

import Foundation

protocol SnappyServiceProtocol {
    associatedtype T
    
    var storedObjects: [T] { get set }
    
    func fetchCollection() -> [T]
    func fetch(with fetchID: String) -> T?
    func save(_ objectToSave: T)
    func save(_ objectsToSave: [T])
    func delete(_ objectToDelete: T)
}

class SnappyService<T: StoredObject>: SnappyServiceProtocol {
    
    private var storage: SnappyStorage<T>
    var storedObjects: [T]
    
    init(storage: SnappyStorage<T>) async {
        self.storage = storage
    }
    
    func fetchCollection() -> [T] {
        return storedObjects
    }
    
    func fetch(with fetchID: String) -> T? {
        return storedObjects.filter { $0.objectID == fetchID }.first
    }
    
    func save(_ objectToSave: T) {
        saveAndReplaceIfNeeded(objectToSave)
        update()
    }
    
    func save(_ objectsToSave: [T]) {
        objectsToSave.forEach { saveAndReplaceIfNeeded($0) }
        update()
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
        update()
    }
    
    private func update() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.storage.sav(collection: self.storedObjects)
            self.storedObjects = self.localStorageService.fetch()
        }
    }
 }
