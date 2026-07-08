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

    func testConcurrentEnterIsGuarded() async {
        let gate = ControllableParentGate()
        let model = AppModel(gate: gate)

        // Start the first attempt but do not await it — it suspends in the gate.
        async let firstAttempt: Void = model.enterParentZone()
        // Let the first attempt reach the gate's suspension point.
        while !model.isAuthenticating { await Task.yield() }

        XCTAssertTrue(model.isAuthenticating)
        XCTAssertEqual(gate.callCount, 1)

        // A second attempt while authenticating must be ignored.
        await model.enterParentZone()
        XCTAssertEqual(gate.callCount, 1, "second attempt should be a no-op")

        // Finish the first attempt.
        gate.complete(with: true)
        await firstAttempt

        XCTAssertEqual(model.zone, .parent)
        XCTAssertFalse(model.isAuthenticating)
    }
}
