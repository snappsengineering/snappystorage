//
//  StorageTests.swift
//  SnappyStorage
//
//  Created by snapps engineering ltd.
//

import XCTest
@testable import SnappyStorage

class StorageTests: XCTestCase {
    
    var storage: Storage<StoredObject>!
    
    override func setUp() {
        super.setUp()
        storage = Storage<StoredObject>(location: Location(destination: .local(.documentDirectory)))
    }
    
    override func tearDown() {
        storage = nil
        super.tearDown()
    }
    
    func testStoreAndFetch() {
        let storedObject = StoredObject()
        storedObject.attributes["key"] = "value"
        
        storage.store(collection: [storedObject])
        let fetchedCollection = storage.fetch()
        
        XCTAssertEqual(fetchedCollection.count, 1)
        XCTAssertEqual(fetchedCollection.first?.attributes["key"] as? String, "value")
    }
    
    func testFetchFromFileURL() {
        let storedObject = StoredObject()
        storedObject.attributes["key"] = "value"
        
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
        let storedObject = StoredObject()
        storedObject.attributes["key"] = "value"
        
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = urls.first!.appendingPathComponent("StoredObject")
        
        storage.writeTo(fileURL: fileURL, collection: [storedObject])
        
        let jsonDecoder = JSONDecoder()
        let jsonData = try! Data(contentsOf: fileURL)
        let fetchedCollection = try! jsonDecoder.decode([StoredObject].self, from: jsonData)
        
        XCTAssertEqual(fetchedCollection.count, 1)
        XCTAssertEqual(fetchedCollection.first?.attributes["key"] as? String, "value")
    }
    
    func testWriteToFileURLFailure() {
        let storedObject = StoredObject()
        storedObject.attributes["key"] = "value"
        
        let fileURL = URL(fileURLWithPath: "/invalid/path")
        
        storage.writeTo(fileURL: fileURL, collection: [storedObject])
        
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    func testFetchReturnEmptyCollection() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = urls.first!.appendingPathComponent("EmptyCollectionFile")
        
        storage.writeTo(fileURL: fileURL, collection: [])
        let fetchedCollection = storage.fetch()
        
        XCTAssertEqual(fetchedCollection.count, 0)
    }
    
    func testFetchFromFileURLCatchError() {
        let fetchedCollection = storage.fetch()
        XCTAssertNil(fetchedCollection)
    }
    
    func testFetchFromFileURLDecodeError() {
        // Create a file with invalid JSON content
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = urls.first!.appendingPathComponent("InvalidJSONFile")
        
        try! "invalid json".write(to: fileURL, atomically: true, encoding: .utf8)
        
        let fetchedCollection = storage.fetch()
        XCTAssertNil(fetchedCollection)
    }
}
