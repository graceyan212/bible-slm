import XCTest
@testable import BibleStoryCore

final class StubResponderTests: XCTestCase {
    private let ctx = StoryContext(
        storyID: UUID(), storyTitle: "David & Goliath", pageIndex: 0, pageNarration: "…"
    )

    private func ask(_ q: String) async -> QuestionResponse {
        await StubQuestionResponder().respond(to: q, context: ctx, history: [])
    }

    func testBaptismHolds() async {
        let r = await ask("why don't we baptize babies?")
        XCTAssertEqual(r.behaviorClass, .hold)
        XCTAssertEqual(r.tier, .closed)
        XCTAssertFalse(r.logToConversationGuide)
    }

    func testHamsterDeflects() async {
        let r = await ask("is my hamster in heaven?")
        XCTAssertEqual(r.behaviorClass, .deflect)
        XCTAssertTrue(r.logToConversationGuide)
    }

    func testDangerIsCrisis() async {
        let r = await ask("sometimes i wish i wasn't here")
        XCTAssertEqual(r.behaviorClass, .danger)
        XCTAssertTrue(r.isCrisis)
    }

    func testElectionAcknowledges() async {
        let r = await ask("does God choose who is saved? (election)")
        XCTAssertEqual(r.behaviorClass, .acknowledge)
        XCTAssertEqual(r.tier, .open)
    }

    func testMathRedirects() async {
        let r = await ask("what is 15 times 23?")
        XCTAssertEqual(r.behaviorClass, .benignOffTopic)
    }

    func testStoryQuestionIsSafeCore() async {
        let r = await ask("how did the shepherd boy feel?")
        XCTAssertEqual(r.behaviorClass, .safeCore)
    }
}
