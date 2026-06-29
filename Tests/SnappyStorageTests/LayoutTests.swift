import XCTest
@testable import SnappyStorage

final class LayoutTests: XCTestCase {

    // MARK: - Layout

    func testDefaults() {
        XCTAssertEqual(Layout.defaultChunked, .chunked(.default))
        XCTAssertTrue(Layout.default.usesDefaultFile)
        XCTAssertTrue(Layout.automatic(AutomaticThresholds()).usesDefaultFile)
        XCTAssertFalse(Layout.perRecord.usesDefaultFile)
        XCTAssertFalse(Layout.chunked(.default).usesDefaultFile)
    }

    func testLayoutVersionKey() {
        XCTAssertEqual(
            Layout.layoutVersionKey(fileName: "Activity"),
            "SnappyStorage.layoutVersion.Activity"
        )
    }
}
