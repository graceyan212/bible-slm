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

    func testEnterParentZoneStaysInChildZoneWhenGateFails() async {
        let gate = MockParentGate(result: false)
        let model = AppModel(gate: gate)

        await model.enterParentZone()

        XCTAssertEqual(model.zone, .child)   // kid-mode lock holds
        XCTAssertEqual(gate.callCount, 1)
    }

    func testExitToChildZoneReturnsToChild() async {
        let model = AppModel(gate: MockParentGate(result: true))
        await model.enterParentZone()
        XCTAssertEqual(model.zone, .parent)   // precondition

        model.exitToChildZone()

        XCTAssertEqual(model.zone, .child)
    }
}
