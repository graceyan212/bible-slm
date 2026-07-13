import XCTest
@testable import BibleStoryCore

final class VerseGuardTests: XCTestCase {
    private let guarder = VerseGuard()

    func testStripsSimpleReference() {
        let input = "My favorite verse is John 3:16 and I love it."
        let output = guarder.clean(input)
        XCTAssertFalse(output.contains("John 3:16"))
        XCTAssertFalse(output.contains("  "))
    }

    func testStripsNumberedBookReference() {
        let input = "Remember what 1 John 4:8 says about love."
        let output = guarder.clean(input)
        XCTAssertFalse(output.contains("1 John 4:8"))
        XCTAssertFalse(output.contains("  "))
    }

    func testStripsGenesisReference() {
        let input = "In the beginning, Genesis 1:1 tells us God created the heavens."
        let output = guarder.clean(input)
        XCTAssertFalse(output.contains("Genesis 1:1"))
        XCTAssertFalse(output.contains("  "))
    }

    func testStripsPsalmReference() {
        let input = "Psalm 23:1 says the Lord is my shepherd."
        let output = guarder.clean(input)
        XCTAssertFalse(output.contains("Psalm 23:1"))
        XCTAssertFalse(output.contains("  "))
    }

    func testLeavesNormalSentenceUnchanged() {
        let input = "God loves you and wants you to be kind to others."
        let output = guarder.clean(input)
        XCTAssertEqual(output, input)
    }

    func testHandlesMultipleReferencesInOneString() {
        let input = "Some kids memorize John 3:16 while others love Psalm 23:1 best."
        let output = guarder.clean(input)
        XCTAssertFalse(output.contains("John 3:16"))
        XCTAssertFalse(output.contains("Psalm 23:1"))
        XCTAssertFalse(output.contains("  "))
    }

    func testResultNeverHasDoubleSpaces() {
        let inputs = [
            "My favorite verse is John 3:16 and I love it.",
            "Remember what 1 John 4:8 says about love.",
            "Some kids memorize John 3:16 while others love Psalm 23:1 best.",
        ]
        for input in inputs {
            let output = guarder.clean(input)
            XCTAssertFalse(output.contains("  "), "Found double space in: \(output)")
        }
    }
}
