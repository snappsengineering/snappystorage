import XCTest
@testable import SnappyStorage

final class StorableTests: XCTestCase {

    func testGenerateHexIDDefaultLength() {
        let id = StoredObject.generateHexID()
        XCTAssertEqual(id.count, 6)
        XCTAssertTrue(id.allSatisfy { $0.isHexDigit })
    }

    func testGenerateHexIDRespectsLength() {
        let id = StoredObject.generateHexID(length: 12)
        XCTAssertEqual(id.count, 12)
        XCTAssertTrue(id.allSatisfy { $0.isHexDigit })
    }

    func testEqualityIsByID() {
        let a = StoredObject(id: "same", name: "a", value: 1)
        let b = StoredObject(id: "same", name: "b", value: 2)
        XCTAssertEqual(a, b)
    }

    func testUpsertReplacesExistingID() {
        var set: Set<StoredObject> = [StoredObject(id: "1", name: "old", value: 0)]
        set.upsert(StoredObject(id: "1", name: "new", value: 1))
        XCTAssertEqual(set.count, 1)
        XCTAssertEqual(set.first?.name, "new")
    }
}
