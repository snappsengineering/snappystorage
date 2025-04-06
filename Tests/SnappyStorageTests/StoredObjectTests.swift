import XCTest
@testable import SnappyStorage

class StoredObjectTests: XCTestCase {
    
    func testStoredObjectInitialization() {
        let storedObject = StoredObject()
        XCTAssertNotNil(storedObject.objectID)
        XCTAssertTrue(storedObject.attributes.isEmpty == false)
    }
    
    func testStoredObjectEncodingAndDecoding() throws {
        let storedObject = StoredObject()
        storedObject.attributes["key"] = "value"
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(storedObject)
        let decodedObject = try decoder.decode(StoredObject.self, from: data)
        XCTAssertEqual(storedObject, decodedObject)
        XCTAssertEqual(decodedObject.attributes["key"] as? String, "value")
    }
    
    func testStoredObjectEquality() {
        let storedObject1 = StoredObject()
        let storedObject2 = StoredObject()
        
        XCTAssertNotEqual(storedObject1, storedObject2)
        
        storedObject2.objectID = storedObject1.objectID
        XCTAssertEqual(storedObject1, storedObject2)
    }
    
    func testStoredObjectAttributes() {
        let storedObject = StoredObject()
        storedObject.attributes["key"] = "value"
        XCTAssertEqual(storedObject.attributes["key"] as? String, "value")
    }
    
    func testStoredObjectDecodingFailure() {
        let invalidData = Data()
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode(StoredObject.self, from: invalidData)) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }
}
