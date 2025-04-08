//
//  StorageTests.swift
//  SnappyStorage
//
//  Created by snapps engineering ltd.
//

import XCTest
@testable import SnappyStorage

class StorageTests: XCTestCase {
    func testStoreAndFetch() {
        let storage = Storage<StoredObject>(destination: .local(.documentDirectory))
        
        let storedObject = StoredObject.value
        
        storage.store(collection: [storedObject])
        let fetchedCollection = storage.fetch()
        
        XCTAssertEqual(fetchedCollection.count, 1)
        XCTAssertEqual(fetchedCollection.first?.attributes["key"] as? String, "value")
    }
    
    func testFetchFromFileURL() {
        let storage = Storage<StoredObject>(destination: .local(.documentDirectory))
        
        let storedObject = StoredObject.value
        
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = urls.first!.appendingPathComponent("StoredObject")
        
        let jsonEncoder = JSONEncoder()
        let jsonData = try! jsonEncoder.encode([storedObject])
        try! jsonData.write(to: fileURL, options: .atomic)
        
        let fetchedCollection = storage.fetch()
        
        XCTAssertNotNil(fetchedCollection)
        XCTAssertEqual(fetchedCollection.count, 1)
        XCTAssertEqual(fetchedCollection.first?.attributes["key"] as? String, "value")
    }
    
    func testWriteToFileURL() {
        let storage = Storage<StoredObject>(destination: .local(.documentDirectory))
        let storedObject = StoredObject.value
        
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = urls.first!.appendingPathComponent("StoredObject")
        
        storage.store(collection: [storedObject])
        
        let jsonDecoder = JSONDecoder()
        let jsonData = try! Data(contentsOf: fileURL)
        let fetchedCollection = try! jsonDecoder.decode([StoredObject].self, from: jsonData)
        
        XCTAssertEqual(fetchedCollection.count, 1)
        XCTAssertEqual(fetchedCollection.first?.attributes["key"] as? String, "value")
    }
    
    func testWriteToFileURLFailure() {
        let storage = Storage<StoredObject>(destination: .custom("/invalid/path"))
        let storedObject = StoredObject.value
        
        storage.store(collection: [storedObject])
        
        XCTAssertFalse(storage.fileExists)
    }
    
    func testFetchReturnEmptyCollection() {
        let storage = Storage<StoredObject>(destination: .local(.documentDirectory))
        storage.store(collection: [])
        let fetchedCollection = storage.fetch()
        
        XCTAssertEqual(fetchedCollection.count, 0)
    }
}
