import XCTest
@testable import BibleStoryCore

@MainActor
final class AppModelTests: XCTestCase {
    func testStartsInChildZone() {
        let model = AppModel(gate: MockParentGate(result: true))
        XCTAssertEqual(model.zone, .child)
    }
}
