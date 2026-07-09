import XCTest
@testable import BibleStoryCore

@MainActor
final class AskSessionModelTests: XCTestCase {
    private func makeSession() -> AskSessionModel {
        let ctx = StoryContext(storyID: UUID(), storyTitle: "T", pageIndex: 0, pageNarration: "n")
        return AskSessionModel(responder: StubQuestionResponder(), context: ctx)
    }

    func testStartsIdle() {
        XCTAssertEqual(makeSession().poliState, .idle)
    }

    func testSubmitProducesReplyAndGrowsThread() async {
        let s = makeSession()
        await s.submit("why don't we baptize babies?")
        XCTAssertEqual(s.poliState, .answering)
        XCTAssertEqual(s.thread.count, 2)                 // kid turn + Poli turn
        XCTAssertEqual(s.response?.behaviorClass, .hold)
        XCTAssertTrue(s.thread.first?.isChild == true)
        XCTAssertFalse(s.thread.last?.isChild == true)
    }

    func testEmptySubmitIsIgnored() async {
        let s = makeSession()
        await s.submit("   ")
        XCTAssertTrue(s.thread.isEmpty)
        XCTAssertEqual(s.poliState, .idle)
    }

    func testFinishAnsweringResetsToIdle() async {
        let s = makeSession()
        await s.submit("hello")
        s.finishAnswering()
        XCTAssertEqual(s.poliState, .idle)
    }
}
