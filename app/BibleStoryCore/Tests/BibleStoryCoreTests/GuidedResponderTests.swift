import XCTest
@testable import BibleStoryCore

/// A test double for `ModelEngine` — records calls and returns/throws on command.
final class SpyEngine: ModelEngine, @unchecked Sendable {
    private(set) var callCount = 0
    var toReturn: String
    var shouldThrow = false
    init(_ toReturn: String = "A warm little answer about the story.") { self.toReturn = toReturn }
    func generate(system: String, messages: [ChatMessage]) async throws -> String {
        callCount += 1
        if shouldThrow { throw NSError(domain: "test", code: 1) }
        return toReturn
    }
}

final class GuidedResponderTests: XCTestCase {
    private let ctx = StoryContext(storyID: UUID(), storyTitle: "Creation",
                                   pageIndex: 0, pageNarration: "In the beginning God made everything.")

    func test_danger_shortCircuits_withoutCallingModel() async {
        let spy = SpyEngine()
        let r = GuidedResponder(engine: spy)
        let resp = await r.respond(to: "sometimes I wish I wasn't here", context: ctx, history: [])
        XCTAssertEqual(resp.behaviorClass, .danger)
        XCTAssertTrue(resp.isCrisis)
        XCTAssertEqual(spy.callCount, 0, "the model must never be called on a crisis input")
    }

    func test_deflect_logsToConversationGuide() async {
        let spy = SpyEngine("That's a wonderful one for your grown-up.")
        let r = GuidedResponder(engine: spy)
        let resp = await r.respond(to: "is my hamster in heaven?", context: ctx, history: [])
        XCTAssertEqual(resp.behaviorClass, .deflect)
        XCTAssertTrue(resp.logToConversationGuide)
        XCTAssertEqual(spy.callCount, 1)
    }

    func test_verseGuard_stripsVerbatimReference() async {
        let spy = SpyEngine("God loves you so much, like it says in John 3:16, forever.")
        let r = GuidedResponder(engine: spy)
        let resp = await r.respond(to: "does God love me?", context: ctx, history: [])
        XCTAssertFalse(resp.spokenText.contains("3:16"), "verbatim chapter:verse must be stripped")
    }

    func test_engineError_returnsWarmFallback_notCrisis() async {
        let spy = SpyEngine(); spy.shouldThrow = true
        let r = GuidedResponder(engine: spy)
        let resp = await r.respond(to: "how did Jonah feel in the big fish?", context: ctx, history: [])
        XCTAssertFalse(resp.isCrisis)
        XCTAssertFalse(resp.spokenText.isEmpty)
    }

    func test_scriptedEngine_endToEnd_producesVerseFreeReply() async {
        let r = GuidedResponder(engine: ScriptedModelEngine())
        let resp = await r.respond(to: "do I have to be dunked all the way under to be baptized?",
                                   context: ctx, history: [])
        XCTAssertEqual(resp.behaviorClass, .hold)
        XCTAssertFalse(resp.spokenText.isEmpty)
        XCTAssertNil(resp.spokenText.range(of: #"\d+:\d+"#, options: .regularExpression),
                     "no chapter:verse should survive")
    }
}
