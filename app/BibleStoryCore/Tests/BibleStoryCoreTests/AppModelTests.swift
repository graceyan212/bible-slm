import XCTest
@testable import BibleStoryCore

@MainActor
final class AppModelTests: XCTestCase {
    func testStartsInChildZone() {
        let model = AppModel(gate: MockParentGate(result: true))
        XCTAssertEqual(model.zone, .child)
    }

    func testEnterParentZoneSucceedsWhenGatePasses() async {
        let gate = MockParentGate(result: true)
        let model = AppModel(gate: gate)

        await model.enterParentZone()

        XCTAssertEqual(model.zone, .parent)
        XCTAssertEqual(gate.callCount, 1)
    }
}
