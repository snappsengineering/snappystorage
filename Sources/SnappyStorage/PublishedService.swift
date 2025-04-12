//
//  PublishedService.swift
//  SnappyStorage
//
//  Created by Shane on 2025-04-11.
//

import Combine

open class PublishedService<T: Storable>: Service<T> {
    @Published public var collectionPublisher: [T] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        super.init()
        self.collectionPublisher = self.collection
    }
    
    open override func save(_ objectToSave: T) {
        super.save(objectToSave)
        self.collectionPublisher = self.collection
    }
    
    open override func save(_ objectsToSave: [T]) {
        super.save(objectsToSave)
        self.collectionPublisher = self.collection
    }
    
    open override func delete(_ objectToDelete: T) {
        super.delete(objectToDelete)
        self.collectionPublisher = self.collection
    }
}
