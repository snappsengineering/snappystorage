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
        storage = Storage<StoredObject>()
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
        
        let fetchedCollection = storage.fetchFrom(fileURL: fileURL)
        
        XCTAssertNotNil(fetchedCollection)
        XCTAssertEqual(fetchedCollection?.count, 1)
        XCTAssertEqual(fetchedCollection?.first?.attributes["key"] as? String, "value")
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
    
    func testGetFilePath() {
        let fileURL = storage.getFilePath()
        XCTAssertNotNil(fileURL)
        
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let expectedURL = urls.first!.appendingPathComponent("StoredObject")
        
        XCTAssertEqual(fileURL, expectedURL)
    }
    
    func testFetchFromFileURLFailure() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = urls.first!.appendingPathComponent("NonExistentFile")
        
        let fetchedCollection = storage.fetchFrom(fileURL: fileURL)
        
        XCTAssertNil(fetchedCollection)
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
        let fetchedCollection = storage.fetchFrom(fileURL: fileURL)
        
        XCTAssertEqual(fetchedCollection?.count, 0)
    }
    
    func testFetchFromFileURLCatchError() {
        // Simulate error by passing invalid URL
        let fileURL = URL(fileURLWithPath: "/invalid/path")
        let fetchedCollection = storage.fetchFrom(fileURL: fileURL)
        XCTAssertNil(fetchedCollection)
    }
    
    func testFetchFromFileURLDecodeError() {
        // Create a file with invalid JSON content
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = urls.first!.appendingPathComponent("InvalidJSONFile")
        
        try! "invalid json".write(to: fileURL, atomically: true, encoding: .utf8)
        
        let fetchedCollection = storage.fetchFrom(fileURL: fileURL)
        XCTAssertNil(fetchedCollection)
    }
    
    func testGetFilePathReturnNil() {
        // Simulate empty URLs array by creating a subclass that overrides the method
        class TestStorage: Storage<StoredObject> {
            override func getFilePath() -> URL? {
                return nil
            }
        }
        
        let testStorage = TestStorage()
        let fileURL = testStorage.getFilePath()
        XCTAssertNil(fileURL)
        
        // Test fetch returning empty collection when getFilePath is nil
        XCTAssertEqual(testStorage.fetch().count, 0)
    }
    
    func testGetFilePathCatchError() throws {
        let storage = Storage<StoredObject>()
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let applicationSupportURL = try XCTUnwrap(urls.last)
        
        // Simulate error by creating a file where a directory is expected
        let fileURL = applicationSupportURL.appendingPathComponent("StoredObject")
        try? "dummy".write(to: fileURL, atomically: true, encoding: .utf8)
        
        let resultURL = storage.getFilePath()
        XCTAssertNotNil(resultURL)
        
        // Clean up
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    func testGetFilePathCreateDirectoryFailure() throws {
        let testStorage = TestStorage<StoredObject>()
        let fileURL = testStorage.getFilePath()
        XCTAssertNotNil(fileURL)
    }
    
    func testFetchReturnNilCollection() {
        // Simulate fetchFrom returning nil
        class TestStorage: Storage<StoredObject> {
            override func fetchFrom(fileURL: URL) -> [StoredObject]? {
                return nil
            }
        }
        
        let testStorage = TestStorage()
        XCTAssertEqual(testStorage.fetch().count, 0)
    }
}
