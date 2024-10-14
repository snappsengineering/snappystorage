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
    
    private var local: Storage<T>
    private var backup: Storage<T>
    private var backupPolicy: BackupPolicy
    private var storedObjects: [T] = []
    
    init(backupPolicy: BackupPolicy, fileManager: FileManager, crypt: Crypt, decoder: JSONDecoder, encoder: JSONEncoder) {
        
        let location = Location<T>(fileManager: fileManager, destination: .local)
        self.local = Storage(location: location, crypt: crypt, decoder: decoder, encoder: encoder)
        
        let backupLocation = Location<T>(fileManager: fileManager, destination: .cloud)
        self.backup = Storage(location: backupLocation, crypt: crypt, decoder: decoder, encoder: encoder)
        self.backupPolicy = backupPolicy
    }

    // load asynchronously from storage
    func load() async throws {
        storedObjects = try await local.load()
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
        objects.forEach {
            updateStorage(with: $0)
        }
        try await commit()
    }
    
    func delete(_ object: T) async throws {
        storedObjects.removeAll(where: { $0 == object })
        try await commit()
    }
    
    func commit() async throws {
        try await local.save(collection: storedObjects)
    }
    
    func commitBackup() async throws {
        try await backup.save(collection: storedObjects)
    }
    
    func restore() async throws {
        storedObjects = try await backup.load()
        try await commit()
    }
    
    func backup() async throws {
        guard let lastBackup = try backup.location.lastUpdated else { return }
        guard backupPolicy.shouldBackup(lastBackup: lastBackup) else { return }
        try await commitBackup()
    }

    // MARK: Private
    
    private func updateStorage(with object: T) {
        if let index = storedObjects.firstIndex(where: { $0 == object }) {
            storedObjects[index] = object
        } else {
            storedObjects.append(object)
        }
    }
 }
