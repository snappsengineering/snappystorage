//
//  Service.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

import Foundation

// MARK: - Protocol

public protocol ServiceProtocol {
    associatedtype T: Storable
    
    var local: Storage<T> { get }
    var backup: Storage<T> { get }
    var backupPolicy: BackupPolicy { get set }
    
    var collection: [T] { get set }

    func pull() async throws
    func fetch(with fetchID: String) async throws -> T
    func save(_ object: T) async throws
    func save(_ objects: [T]) async throws
    func delete(_ object: T)  async throws
}

open class Service<T: Storable>: ServiceProtocol {

    // MARK: Public Properties
    
    public var local: Storage<T>
    public var backup: Storage<T>
    public var backupPolicy: BackupPolicy
    
    public var collection: [T] = []
    
    // MARK: init

    public init(backupPolicy: BackupPolicy, localDirectory: FileManager.SearchPathDirectory) async {
        
        self.backupPolicy = backupPolicy
        
        let fileManager = FileManager.default
        
        let location = Location<T>(destination: .local(.documentDirectory), fileManager: fileManager)
        self.local = Storage(location: location)

        let backupLocation = Location<T>(destination: .cloud, fileManager: fileManager)
        self.backup = Storage(location: backupLocation)
        
        do {
            try await pull()
        } catch {
            collection = []
        }
    }
    
    public func pull() async throws {
        collection = try await local.load()
    }
    
    // MARK: Local DB Operations
    
    public func fetch(with fetchID: String) async throws -> T {
        guard let item = collection.filter({ $0.id == fetchID }).first
        else { throw SnappyError.dataNotFound }
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
        collection.removeAll(where: { $0 == object })
        try await commit()
    }
    
    // MARK: iCloud Backup
    
    public func restore() async throws {
        guard backupPolicy.frequency != .never
        else { throw SnappyError.invalidOperationError }
        collection = try await backup.load()
        try await commit()
    }
    
    public func backup() async throws {
        guard backupPolicy.frequency != .never,
              let lastBackup = try backup.location.lastUpdated,
              backupPolicy.shouldBackup(lastBackup: lastBackup)
        else { return }
        try await commitBackup()
    }

    // MARK: Private
    
    private func commit() async throws {
        try await local.save(collection: collection)
    }
    
    private func commitBackup() async throws {
        guard backupPolicy.frequency != .never else { throw SnappyError.invalidOperationError }
        try await backup.save(collection: collection)
    }
    
    private func updateStorage(with object: T) {
        if let index = collection.firstIndex(where: { $0 == object }) {
            collection[index] = object
        } else {
            collection.append(object)
        }
    }
 }
