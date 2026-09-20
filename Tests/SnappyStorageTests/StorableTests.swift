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

    // MARK: - generateHexID (randomized edge lengths)

    func testGenerateHexIDZeroLengthProducesEmptyString() {
        XCTAssertEqual(StoredObject.generateHexID(length: 0), "")
    }

    func testGenerateHexIDAcrossRandomLengthsAlwaysMatchesRequestedLength() {
        // Sweep a spread of lengths (including 1 and a large one) rather than one fixed value,
        // to catch off-by-one errors that a single-length test could miss.
        for length in [0, 1, 2, 5, 6, 7, 16, 32, 64, 128] {
            let id = StoredObject.generateHexID(length: length)
            XCTAssertEqual(id.count, length, "length \(length) produced \(id.count) characters")
            XCTAssertTrue(id.allSatisfy { $0.isHexDigit }, "id '\(id)' contains a non-hex character")
        }
    }

    func testGenerateHexIDIsUppercase() {
        // Documents the actual alphabet ("0123456789ABCDEF") so a future change to lowercase
        // is a deliberate, visible diff here.
        let id = StoredObject.generateHexID(length: 200)
        XCTAssertTrue(id.allSatisfy { !$0.isLowercase })
    }

    func testGenerateHexIDsAreNotAllIdentical() {
        // Weak randomness regression guard: 20 draws at a reasonable length should not all
        // collide. Not a strong statistical test, but catches "always returns the same value"
        // bugs (e.g. a broken/reseeded RNG) cheaply and deterministically enough to keep in CI.
        let ids = (0..<20).map { _ in StoredObject.generateHexID(length: 8) }
        XCTAssertGreaterThan(Set(ids).count, 1)
    }
}
