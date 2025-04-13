//
//  ServiceTests.swift
//  SnappyStorage
//
//  Created by snapps engineering ltd.
//

import XCTest
@testable import SnappyStorage

class ServiceTests: XCTestCase {
    
    var service: Service<StoredObject>!
    
    override func setUp() {
        super.setUp()
        service = Service<StoredObject>()
        // Clear the storage before each test to avoid interference between tests
        service.collection.removeAll()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    func testRefreshCollection() {
        service.load()
        XCTAssertNotNil(service.collection)
    }
    
    func testSaveAndFetchObject() {
        let storedObject = StoredObject.value
        
        service.save(storedObject)
        
        let fetchedObject = service.fetch(for: storedObject.objectID)
        XCTAssertNotNil(fetchedObject)
        XCTAssertEqual(fetchedObject?.key as? String, "value")
    }
    
    func testSaveMultipleObjects() {
        let storedObject1 = StoredObject.value1
        let storedObject2 = StoredObject.value2
        
        service.save([storedObject1, storedObject2])
        
        service.load()
        XCTAssertEqual(service.collection.count, 2)
        
        let fetchedObject1 = service.fetch(for: storedObject1.objectID)
        let fetchedObject2 = service.fetch(for: storedObject2.objectID)
        
        XCTAssertEqual(fetchedObject1?.key as? String, "value1")
        XCTAssertEqual(fetchedObject2?.key as? String, "value2")
    }
    
    func testDeleteObject() {
        let storedObject = StoredObject.value
        service.save(storedObject)
        
        service.delete(storedObject)
        
        let fetchedObject = service.fetch(for: storedObject.objectID)
        XCTAssertNil(fetchedObject)
    }
    
    func testSaveAndReplaceIfNeeded() {
        var storedObject = StoredObject.value
        
        service.save(storedObject)
        
        storedObject.key = "newValue"
        service.save(storedObject)
        
        let fetchedObject = service.fetch(for: storedObject.objectID)
        XCTAssertEqual(fetchedObject?.key as? String, "newValue")
    }
    
    func testUpdate() {
        let storedObject = StoredObject.value
        
        service.save(storedObject)
        
        let fetchedObject = service.fetch(for: storedObject.objectID)
        XCTAssertNotNil(fetchedObject)
        XCTAssertEqual(fetchedObject?.key as? String, "value")
    }
    
    func testSaveAndReplaceIfNeededNewObject() {
        let storedObject1 = StoredObject.value1
        let storedObject2 = StoredObject.value2
        
        service.save(storedObject1)
        service.save(storedObject2)
        
        service.load()
        XCTAssertEqual(service.collection.count, 2)
        
        let fetchedObject1 = service.fetch(for: storedObject1.objectID)
        let fetchedObject2 = service.fetch(for: storedObject2.objectID)
        
        XCTAssertEqual(fetchedObject1?.key as? String, "value1")
        XCTAssertEqual(fetchedObject2?.key as? String, "value2")
    }
}
