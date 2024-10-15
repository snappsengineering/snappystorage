//
//  Service.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

import Foundation

// MARK: - Protocol

public protocol ServiceProtocol {
    associatedtype T
    
    func load() async throws -> [T]
    func fetch(with fetchID: String) async throws -> T
    func save(_ object: T) async throws
    func save(_ objects: [T]) async throws
    func delete(_ object: T)  async throws
}

open class Service<T: Storable>: ServiceProtocol {
    
    // MARK: Private Properties
    
    private var local: Storage<T>?
    private var backup: Storage<T>?
    private var backupPolicy: BackupPolicy
    
    // MARK: Public Properties
    
    public var storedObjects: [T] = []
    
    // MARK: init
    
    public init(backupPolicy: BackupPolicy, encryptionEnabled: Bool) {
        
        self.backupPolicy = backupPolicy
        let crypt = Crypt.init(isEnabled: encryptionEnabled)
        
        self.setStorage(backupPolicy: backupPolicy, crypt: crypt)
    }
    
    private func setStorage(backupPolicy: BackupPolicy, crypt: Crypt) {
        let fileManager = FileManager.default
        
        let location = Location<T>(destination: .local, fileManager: fileManager)
        self.local = Storage(crypt: crypt, location: location)
        
        guard backupPolicy.frequency != .never else { return }
        
        let backupLocation = Location<T>(destination: .cloud, fileManager: fileManager)
        self.backup = Storage(crypt: crypt, location: backupLocation)
    }
    
    // MARK: Local DB Operations

    public func load() async throws -> [T] {
        try await pull()
        return storedObjects
    }
    
    public func fetch(with fetchID: String) async throws -> T {
        guard let item = storedObjects.filter({ $0.objectID == fetchID }).first else { throw SnappyError.dataNotFound }
        return item
    }
    
    public func save(_ object: T) async throws {
        updateStorage(with: object)
        try await commit()
    }
    
    public func save(_ objects: [T]) async throws {
        objects.forEach {
            updateStorage(with: $0)
        }
        try await commit()
    }
    
    public func delete(_ object: T) async throws {
        storedObjects.removeAll(where: { $0 == object })
        try await commit()
    }
    
    // MARK: iCloud Backup
    
    public func restore() async throws {
        guard backupPolicy.frequency != .never,
        let backup else { throw SnappyError.invalidOperationError }
        storedObjects = try await backup.load()
        try await commit()
    }
    
    public func backup() async throws {
        guard backupPolicy.frequency != .never,
        let backup else { throw SnappyError.invalidOperationError }
        guard let lastBackup = try backup.location.lastUpdated else { return }
        guard backupPolicy.shouldBackup(lastBackup: lastBackup) else { return }
        try await commitBackup()
    }

    // MARK: Private
    
    private func pull() async throws {
        guard let fetchedObjects = try await local?.load() else { throw SnappyError.emptyDataError }
        storedObjects = fetchedObjects
    }
    
    private func commit() async throws {
        try await local?.save(collection: storedObjects)
    }
    
    private func commitBackup() async throws {
        guard backupPolicy.frequency != .never,
        let backup else { throw SnappyError.invalidOperationError }
        try await backup.save(collection: storedObjects)
    }
    
    private func updateStorage(with object: T) {
        if let index = storedObjects.firstIndex(where: { $0 == object }) {
            storedObjects[index] = object
        } else {
            storedObjects.append(object)
        }
    }
 }
