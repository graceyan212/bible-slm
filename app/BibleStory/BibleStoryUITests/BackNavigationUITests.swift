import XCTest

/// Drives REAL taps on the back affordances and asserts the map returns.
/// This is the proof that "back" works — not a code assertion.
final class BackNavigationUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: helpers

    private func launch(_ args: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = args
        app.launch()
        return app
    }

    /// The map is on screen when a story cover ("Creation") is present.
    private func creationCover(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Creation")).firstMatch
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    // MARK: tests

    /// (1) Reader page 0 → tap top-bar back arrow → map.
    func testReaderBackArrowReturnsToMap() {
        let app = launch(["-uiPreviewChild"])

        let cover = creationCover(app)
        XCTAssertTrue(cover.waitForExistence(timeout: 5), "Map cover 'Creation' should be visible at launch")
        snap(app, "01-map-before")

        cover.tap()

        let back = app.buttons["Back"]
        XCTAssertTrue(back.waitForExistence(timeout: 5), "Reader back arrow should appear after opening a story")
        XCTAssertTrue(app.staticTexts["Creation"].exists, "Reader should show the story title")
        snap(app, "02-reader-open")

        back.tap()

        XCTAssertTrue(cover.waitForExistence(timeout: 5), "Tapping back must return to the map (cover visible again)")
        XCTAssertFalse(app.buttons["Back"].exists, "Reader back arrow should be gone once on the map")
        snap(app, "03-map-after-back")
    }

    /// (2) Reader completion screen → tap "BACK TO THE MAP" → map.
    func testCompletionBackReturnsToMap() {
        let app = launch(["-uiPreviewChild", "-uiPreviewStory", "-uiPreviewStoryDone"])

        let backToMap = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "BACK TO THE MAP")).firstMatch
        XCTAssertTrue(backToMap.waitForExistence(timeout: 5), "Completion 'BACK TO THE MAP' button should be visible")
        snap(app, "04-completion")

        backToMap.tap()

        XCTAssertTrue(creationCover(app).waitForExistence(timeout: 5), "Completion back must return to the map")
        snap(app, "05-map-after-completion-back")
    }

    /// (3) Ask/Compass → tap toolbar back → leaves the compass.
    func testCompassBackReturns() {
        let app = launch(["-uiPreviewChild"])

        let askTab = app.buttons["Ask"]
        XCTAssertTrue(askTab.waitForExistence(timeout: 5), "Ask tab should exist")
        askTab.tap()

        let talk = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Tap to talk")).firstMatch
        XCTAssertTrue(talk.waitForExistence(timeout: 5), "Ask panel 'Tap to talk' should appear")
        talk.tap()

        let compassBar = app.navigationBars["Ask Poli"]
        XCTAssertTrue(compassBar.waitForExistence(timeout: 5), "Compass should push with an 'Ask Poli' nav bar")
        snap(app, "06-compass-open")

        compassBar.buttons["Map"].tap()

        XCTAssertTrue(askTab.waitForExistence(timeout: 5), "Compass back should return to the child zone")
        XCTAssertFalse(app.navigationBars["Ask Poli"].exists, "Compass should be dismissed after back")
        snap(app, "07-after-compass-back")
    }
}
