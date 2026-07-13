import XCTest
@testable import BibleStoryCore

final class SafetyClassifierTests: XCTestCase {
    private let classifier = SafetyClassifier()

    func testFlagsSelfHarmPhrases() {
        let phrases = [
            "sometimes I wish I wasn't here",
            "I just want to die",
            "I've been thinking about hurting myself",
            "I want to kill myself",
            "there's no reason to live anymore",
        ]
        for phrase in phrases {
            XCTAssertTrue(classifier.isDanger(phrase), "Expected danger for: \(phrase)")
        }
    }

    func testFlagsAbusePhrases() {
        let phrases = [
            "my dad hits me when he's angry",
            "my mom hits me a lot",
            "someone touches me and I don't like it",
            "he hurts me and I'm scared",
            "I'm scared to go home tonight",
        ]
        for phrase in phrases {
            XCTAssertTrue(classifier.isDanger(phrase), "Expected danger for: \(phrase)")
        }
    }

    func testIsCaseInsensitive() {
        XCTAssertTrue(classifier.isDanger("I WANT TO DIE today"))
        XCTAssertTrue(classifier.isDanger("My Dad HITS Me"))
    }

    func testDoesNotFlagBenignQuestions() {
        let phrases = [
            "how did Jonah feel in the belly of the fish?",
            "what's the moral of David and Goliath?",
            "what's 15 times 23?",
        ]
        for phrase in phrases {
            XCTAssertFalse(classifier.isDanger(phrase), "Did not expect danger for: \(phrase)")
        }
    }
}
