import XCTest
@testable import BibleStoryCore

@MainActor
final class AppEnvironmentTests: XCTestCase {
    private func env(gate pass: Bool) -> AppEnvironment {
        AppEnvironment(responder: StubQuestionResponder(), gate: MockParentGate(result: pass))
    }

    func testStartsInOnboarding() {
        XCTAssertEqual(env(gate: true).phase, .onboarding)
    }

    func testCompleteOnboardingEntersChildZone() {
        let e = env(gate: true)
        e.completeOnboarding(child: ChildProfile(name: "Mia", age: 8), translation: .esv)
        XCTAssertEqual(e.phase, .child)
        XCTAssertEqual(e.activeChild?.name, "Mia")
        XCTAssertEqual(e.translation, .esv)
    }

    func testEnterParentStaysInChildWhenGateFails() async {
        let e = env(gate: false)
        e.completeOnboarding(child: ChildProfile(name: "M", age: 7), translation: .nirv)
        await e.enterParentZone()
        XCTAssertEqual(e.phase, .child)   // kid-mode lock holds
    }

    func testEnterAndExitParentZone() async {
        let e = env(gate: true)
        e.completeOnboarding(child: ChildProfile(name: "M", age: 7), translation: .nirv)
        await e.enterParentZone()
        XCTAssertEqual(e.phase, .parent)
        e.exitToChildZone()
        XCTAssertEqual(e.phase, .child)
    }
}
