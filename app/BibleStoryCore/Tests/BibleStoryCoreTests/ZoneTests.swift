import XCTest
@testable import BibleStoryCore

final class ZoneTests: XCTestCase {
    func testChildAndParentAreDistinct() {
        XCTAssertNotEqual(Zone.child, Zone.parent)
    }
}
