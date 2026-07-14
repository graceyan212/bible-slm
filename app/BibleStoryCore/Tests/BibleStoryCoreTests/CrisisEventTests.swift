import XCTest
@testable import BibleStoryCore

final class CrisisEventTests: XCTestCase {
    func testSanitizerCollapsesWhitespaceOnShortInput() {
        let summary = CrisisEvent.sanitizedSummary(from: "  scary   words \n here ")
        XCTAssertEqual(summary, "scary words here")
    }

    func testSanitizerCapsAndSingleLinesLongInput() {
        // A long, multi-line, transcript-like reason must never persist whole.
        let raw = String(repeating: "the child said something upsetting ", count: 20)
            + "\n\nand more detail on a new line"
        let summary = CrisisEvent.sanitizedSummary(from: raw)

        XCTAssertLessThanOrEqual(summary.count, CrisisEvent.maxSummaryLength + 1)
        XCTAssertFalse(summary.contains("\n"), "summary must be single-line")
        XCTAssertTrue(summary.hasSuffix("…"), "over-length summary is truncated")
        XCTAssertNotEqual(summary, raw, "raw transcript must not pass through verbatim")
    }

    func testSanitizerReturnsNeutralDefaultForEmptyInput() {
        XCTAssertFalse(CrisisEvent.sanitizedSummary(from: "   \n  ").isEmpty)
    }

    func testEventStoresSanitizedSummary() {
        let id = UUID()
        let childID = UUID()
        let when = Date(timeIntervalSince1970: 1_700_000_000)
        let event = CrisisEvent(
            id: id,
            childID: childID,
            createdAt: when,
            triggerSummary: CrisisEvent.sanitizedSummary(from: "one   two")
        )
        XCTAssertEqual(event.id, id)
        XCTAssertEqual(event.childID, childID)
        XCTAssertEqual(event.createdAt, when)
        XCTAssertEqual(event.triggerSummary, "one two")
    }
}
