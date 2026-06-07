import XCTest
@testable import SnappyStorage

final class CollectionLayoutTests: XCTestCase {

    func testDefaults() {
        XCTAssertEqual(CollectionLayout.defaultChunked, .chunked(.default))
        XCTAssertTrue(CollectionLayout.monolith.usesMonolithFile)
        XCTAssertTrue(CollectionLayout.automatic(.default).usesMonolithFile)
        XCTAssertFalse(CollectionLayout.perRecord.usesMonolithFile)
        XCTAssertFalse(CollectionLayout.chunked(.default).usesMonolithFile)
    }

    func testLayoutVersionKey() {
        XCTAssertEqual(
            CollectionLayout.layoutVersionKey(fileName: "Activity"),
            "SnappyStorage.layoutVersion.Activity"
        )
    }
}
