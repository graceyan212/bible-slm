# P3 — Story Experience Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the child story experience — a friendly illustrated Library, a full-bleed Story Player that plays pre-rendered narration audio with page turns and pause/replay/continue, gentle "wonder pause" points, and a completion/reward — plus the content-asset pipeline (a JSON schema for a story and one real committed sample story). This is PRD §5.2 (story session), §6.1 (content/narration), Epic B (B1–B5), and the Child-zone half of §8's screen inventory.

**Architecture:** All decision logic lives in the platform-agnostic `BibleStoryCore` Swift Package and is unit-tested from the command line with `swift test` — no simulator, fast TDD. The three external seams — narration playback (`NarrationPlayer`), story loading (`StoryLibrary`), and progress persistence (`StoryProgressStore`) — are `public protocol`s so the core stays testable with mocks/in-memory doubles. The two view-facing state objects, `StoryPlayerModel` (a page state machine that drives a `NarrationPlayer`) and `LibraryModel` (stories + completed markers), are `@MainActor @Observable`. A testable `StoryDecoder` turns the story JSON schema into `[Story]`. The Apple-framework glue — `AVFoundationNarrationPlayer`, `BundledStoryLibrary`, `UserDefaultsStoryProgressStore`, and the SwiftUI `LibraryView` / `StoryPlayerView` — lives in the `BibleStory` app target and is verified by `xcodebuild` build + a manual Simulator checklist. `LibraryView` becomes the child-zone home, replacing P1's "Story Library" placeholder in `ChildZoneView`.

**Tech Stack:** Swift 6, SwiftUI, Observation framework, AVFoundation (audio playback), Foundation (`Codable`/`JSONDecoder`, `UserDefaults`), Swift Package Manager + XCTest, XcodeGen. Depends on P1 (`AppModel`, `Zone`, `ParentGate`, `BibleStory` app target, `BibleStoryCore` package). No third-party dependencies.

## Global Constraints

_Every task's requirements implicitly include this section._

- **Deployment target:** iOS 17.0 minimum (enables the `@Observable` macro). Revisit against PRD Open Question Q6 before launch.
- **Language/tools:** `swift-tools-version: 6.0`; Swift 6 language mode.
- **Layering (from P1 / shared-interfaces):** all decision logic lives in `BibleStoryCore` and is unit-tested via `swift test`. SwiftUI views and Apple-framework glue live in the `BibleStory` app target and are verified by build + manual run. Regenerate the Xcode project with `xcodegen generate` (from `app/BibleStory/`) after adding files; `project.yml` is the source of truth.
- **Cross-plan contract:** use ONLY the exact type names and signatures from `docs/superpowers/plans/2026-07-08-shared-interfaces.md` under "P3 — Story experience" (`StoryPage`, `Story`, `StoryLibrary`, `NarrationPlayer`, `StoryProgressStore`, `StoryPlayerModel`, `LibraryModel`). Additive changes to P1 files only.
- **Never-generate-Scripture invariant (PRD §1.3, §7):** narration is FIXED, pre-vetted content shipped as assets. The story pipeline never generates or synthesizes verse text at runtime; the model reads and plays only what is committed. This plan adds no text-generation path.
- **Privacy (PRD §10, §9.3):** narration audio is content, not user data. This layer processes no child speech and stores no child PII; per-child completion markers use a device-local id supplied by the app layer.
- **Content-ops boundary:** illustration art and premium-TTS narration audio are produced OUTSIDE this plan (a content-ops task, PRD FR-1). Placeholder image/audio asset *names* are committed in the JSON; the JSON and decoder are real and tested. Views render a graceful placeholder when a named asset is absent, and the audio player no-ops (never crashes) when an audio file is missing.
- **Directory:** all iOS work lives under `app/` at the repo root. Run `git`, `swift test`, and `python3` commands from the repo root `bible-slm/` unless a step says otherwise.

---

### Task 1: `StoryPage` and `Story` value types

**Files:**
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/StoryPage.swift`
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/Story.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/StoryTests.swift`

**Interfaces:**
- Consumes: nothing new (Foundation `UUID`).
- Produces (exact shared-contract signatures):
  - `public struct StoryPage: Identifiable, Sendable, Equatable, Codable` with `public let id: UUID`, `imageName: String`, `narrationText: String`, `audioAssetName: String`, `isWonderPause: Bool`, plus a `public init`.
  - `public struct Story: Identifiable, Sendable, Equatable, Codable` with `public let id: UUID`, `title: String`, `coverImageName: String`, `estimatedMinutes: Int`, `pages: [StoryPage]`, plus a `public init`.

- [ ] **Step 1: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/StoryTests.swift`:
```swift
import XCTest
import Foundation
@testable import BibleStoryCore

final class StoryTests: XCTestCase {
    private func makeStory() -> Story {
        Story(
            id: UUID(uuidString: "00000000-0000-4000-8000-0000000000AA")!,
            title: "David & Goliath",
            coverImageName: "cover",
            estimatedMinutes: 6,
            pages: [
                StoryPage(
                    id: UUID(uuidString: "00000000-0000-4000-8000-0000000000B1")!,
                    imageName: "p1",
                    narrationText: "Once there was a shepherd boy.",
                    audioAssetName: "p1_audio",
                    isWonderPause: false
                ),
                StoryPage(
                    id: UUID(uuidString: "00000000-0000-4000-8000-0000000000B2")!,
                    imageName: "p2",
                    narrationText: "I wonder how he felt.",
                    audioAssetName: "p2_audio",
                    isWonderPause: true
                ),
            ]
        )
    }

    func testStoryExposesPagesInOrder() {
        let story = makeStory()
        XCTAssertEqual(story.pages.count, 2)
        XCTAssertEqual(story.pages[0].imageName, "p1")
        XCTAssertTrue(story.pages[1].isWonderPause)
    }

    func testStoryCodableRoundTrip() throws {
        let story = makeStory()
        let data = try JSONEncoder().encode(story)
        let decoded = try JSONDecoder().decode(Story.self, from: data)
        XCTAssertEqual(decoded, story)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "StoryTests"
```
Expected: BUILD FAILURE — `cannot find 'Story' in scope` / `cannot find 'StoryPage' in scope`.

- [ ] **Step 3: Implement `StoryPage`**

Create `app/BibleStoryCore/Sources/BibleStoryCore/StoryPage.swift`:
```swift
import Foundation

/// One page of a story: a full-bleed illustration, its vetted narration text,
/// the pre-rendered narration audio asset, and whether this page invites the
/// child to wonder aloud (the ask-a-question loop hooks in here in P4).
public struct StoryPage: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public let imageName: String        // bundled illustration asset
    public let narrationText: String    // vetted, ~part of a 400–700 word story
    public let audioAssetName: String   // pre-rendered premium-TTS narration asset
    public let isWonderPause: Bool       // invites the ask-a-question loop

    public init(
        id: UUID,
        imageName: String,
        narrationText: String,
        audioAssetName: String,
        isWonderPause: Bool
    ) {
        self.id = id
        self.imageName = imageName
        self.narrationText = narrationText
        self.audioAssetName = audioAssetName
        self.isWonderPause = isWonderPause
    }
}
```

- [ ] **Step 4: Implement `Story`**

Create `app/BibleStoryCore/Sources/BibleStoryCore/Story.swift`:
```swift
import Foundation

/// A complete, vetted story: cover, estimated length, and ordered pages.
public struct Story: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public let title: String
    public let coverImageName: String
    public let estimatedMinutes: Int
    public let pages: [StoryPage]

    public init(
        id: UUID,
        title: String,
        coverImageName: String,
        estimatedMinutes: Int,
        pages: [StoryPage]
    ) {
        self.id = id
        self.title = title
        self.coverImageName = coverImageName
        self.estimatedMinutes = estimatedMinutes
        self.pages = pages
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "StoryTests"
```
Expected: PASS — `Test Suite 'StoryTests' passed`.

- [ ] **Step 6: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): add Story and StoryPage value types"
```

---

### Task 2: `StoryDecoder` + story JSON schema

Defines the on-disk story JSON schema and a testable decoder that turns it into `[Story]`, validating the schema version and rejecting structurally invalid content (a story with no pages, or an empty required asset name). This is the content pipeline's core.

**Files:**
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/StoryDecoder.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/StoryDecoderTests.swift`

**Interfaces:**
- Consumes: `Story`, `StoryPage` (Task 1).
- Produces:
  - `public enum StoryDecodingError: Error, Equatable` with `case unsupportedSchemaVersion(found: Int, supported: Int)`, `case storyHasNoPages(storyID: UUID)`, `case emptyAssetName(storyID: UUID)`.
  - `public enum StoryDecoder` with `public static let schemaVersion: Int` and `public static func decode(_ data: Data) throws -> [Story]`.
- Schema (documented in the source): a JSON object `{ "schemaVersion": 1, "stories": [ Story… ] }` where each `Story` is `{ id, title, coverImageName, estimatedMinutes, pages: [ { id, imageName, narrationText, audioAssetName, isWonderPause } ] }`. `id` fields are UUID strings.

- [ ] **Step 1: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/StoryDecoderTests.swift`:
```swift
import XCTest
import Foundation
@testable import BibleStoryCore

final class StoryDecoderTests: XCTestCase {
    private func data(_ json: String) -> Data { Data(json.utf8) }

    private let validJSON = """
    {
      "schemaVersion": 1,
      "stories": [
        {
          "id": "11111111-1111-4111-8111-111111111111",
          "title": "Sample Story",
          "coverImageName": "sample_cover",
          "estimatedMinutes": 5,
          "pages": [
            {
              "id": "22222222-2222-4222-8222-222222222222",
              "imageName": "sample_p1",
              "narrationText": "Once upon a time.",
              "audioAssetName": "sample_p1_narration",
              "isWonderPause": false
            },
            {
              "id": "33333333-3333-4333-8333-333333333333",
              "imageName": "sample_p2",
              "narrationText": "I wonder what happens next.",
              "audioAssetName": "sample_p2_narration",
              "isWonderPause": true
            }
          ]
        }
      ]
    }
    """

    func testDecodesValidLibrary() throws {
        let stories = try StoryDecoder.decode(data(validJSON))
        XCTAssertEqual(stories.count, 1)
        XCTAssertEqual(stories[0].title, "Sample Story")
        XCTAssertEqual(stories[0].pages.count, 2)
        XCTAssertFalse(stories[0].pages[0].isWonderPause)
        XCTAssertTrue(stories[0].pages[1].isWonderPause)
    }

    func testRejectsUnsupportedSchemaVersion() {
        let json = validJSON.replacingOccurrences(
            of: "\"schemaVersion\": 1",
            with: "\"schemaVersion\": 99"
        )
        XCTAssertThrowsError(try StoryDecoder.decode(data(json))) { error in
            XCTAssertEqual(
                error as? StoryDecodingError,
                .unsupportedSchemaVersion(found: 99, supported: StoryDecoder.schemaVersion)
            )
        }
    }

    func testRejectsStoryWithNoPages() {
        let json = """
        {
          "schemaVersion": 1,
          "stories": [
            {
              "id": "11111111-1111-4111-8111-111111111111",
              "title": "Empty",
              "coverImageName": "cover",
              "estimatedMinutes": 1,
              "pages": []
            }
          ]
        }
        """
        XCTAssertThrowsError(try StoryDecoder.decode(data(json))) { error in
            XCTAssertEqual(
                error as? StoryDecodingError,
                .storyHasNoPages(
                    storyID: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
                )
            )
        }
    }

    func testRejectsEmptyAssetName() {
        let json = validJSON.replacingOccurrences(
            of: "\"audioAssetName\": \"sample_p1_narration\"",
            with: "\"audioAssetName\": \"\""
        )
        XCTAssertThrowsError(try StoryDecoder.decode(data(json))) { error in
            XCTAssertEqual(
                error as? StoryDecodingError,
                .emptyAssetName(
                    storyID: UUID(uuidString: "11111111-1111-4111-8111-111111111111")!
                )
            )
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "StoryDecoderTests"
```
Expected: BUILD FAILURE — `cannot find 'StoryDecoder' in scope`.

- [ ] **Step 3: Implement `StoryDecoder`**

Create `app/BibleStoryCore/Sources/BibleStoryCore/StoryDecoder.swift`:
```swift
import Foundation

/// Errors surfaced when decoding the story JSON schema.
public enum StoryDecodingError: Error, Equatable {
    /// The file's `schemaVersion` is not the one this build understands.
    case unsupportedSchemaVersion(found: Int, supported: Int)
    /// A story has an empty `pages` array — a story must have at least one page.
    case storyHasNoPages(storyID: UUID)
    /// A required asset-name field (title, cover, page image, or page audio) was blank.
    case emptyAssetName(storyID: UUID)
}

/// Decodes the bundled story JSON schema into vetted `Story` values.
///
/// Schema (`stories.json`):
/// ```
/// {
///   "schemaVersion": 1,
///   "stories": [
///     {
///       "id": "<uuid>",
///       "title": "…",
///       "coverImageName": "…",
///       "estimatedMinutes": 6,
///       "pages": [
///         { "id": "<uuid>", "imageName": "…", "narrationText": "…",
///           "audioAssetName": "…", "isWonderPause": false }
///       ]
///     }
///   ]
/// }
/// ```
public enum StoryDecoder {
    /// The schema version this build reads.
    public static let schemaVersion = 1

    private struct File: Decodable {
        let schemaVersion: Int
        let stories: [Story]
    }

    /// Decodes a story-library JSON payload into `[Story]`, validating the
    /// schema version and each story's structure.
    public static func decode(_ data: Data) throws -> [Story] {
        let file = try JSONDecoder().decode(File.self, from: data)

        guard file.schemaVersion == schemaVersion else {
            throw StoryDecodingError.unsupportedSchemaVersion(
                found: file.schemaVersion,
                supported: schemaVersion
            )
        }

        for story in file.stories {
            guard !story.pages.isEmpty else {
                throw StoryDecodingError.storyHasNoPages(storyID: story.id)
            }

            let namesPresent =
                !story.title.isEmpty &&
                !story.coverImageName.isEmpty &&
                story.pages.allSatisfy { !$0.imageName.isEmpty && !$0.audioAssetName.isEmpty }

            guard namesPresent else {
                throw StoryDecodingError.emptyAssetName(storyID: story.id)
            }
        }

        return file.stories
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "StoryDecoderTests"
```
Expected: PASS — all four tests green.

- [ ] **Step 5: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): add StoryDecoder and story JSON schema with validation"
```

---

### Task 3: `NarrationPlayer` protocol + `StoryPlayerModel` initial state

Introduces the playback seam and the story state machine's starting state. The model opens on page 0, not yet playing, not finished, and exposes the current page.

**Files:**
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/NarrationPlayer.swift`
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/StoryPlayerModel.swift`
- Create: `app/BibleStoryCore/Tests/BibleStoryCoreTests/Fixtures.swift`
- Modify: `app/BibleStoryCore/Tests/BibleStoryCoreTests/TestDoubles.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/StoryPlayerModelTests.swift`

**Interfaces:**
- Consumes: `Story`, `StoryPage` (Task 1).
- Produces:
  - `public protocol NarrationPlayer: Sendable` with `func play(assetNamed name: String) async`, `func pause() async`, `func stop() async`.
  - `@MainActor @Observable public final class StoryPlayerModel` with `public init(story: Story, player: NarrationPlayer)`, `public let story: Story`, `public private(set) var currentPageIndex: Int` (0), `public private(set) var isPlaying: Bool` (false), `public private(set) var finished: Bool` (false), and `public var currentPage: StoryPage`.
  - Test double `MockNarrationPlayer` (records `playedAssets`, `pauseCount`, `stopCount`).
  - Test fixture `StoryFixtures.story` (3 pages; page index 1 is a wonder pause).

- [ ] **Step 1: Add the `MockNarrationPlayer` test double**

Append to `app/BibleStoryCore/Tests/BibleStoryCoreTests/TestDoubles.swift`:
```swift

/// Records every call so tests can assert on playback behavior.
/// `@MainActor` so it runs on the same actor as `StoryPlayerModel`; its `async`
/// methods satisfy `NarrationPlayer`'s `async` requirements (same pattern as
/// P1's `ControllableParentGate`).
@MainActor
final class MockNarrationPlayer: NarrationPlayer {
    private(set) var playedAssets: [String] = []
    private(set) var pauseCount = 0
    private(set) var stopCount = 0

    nonisolated init() {}

    func play(assetNamed name: String) async { playedAssets.append(name) }
    func pause() async { pauseCount += 1 }
    func stop() async { stopCount += 1 }
}
```

- [ ] **Step 2: Add the shared test fixture**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/Fixtures.swift`:
```swift
import Foundation
@testable import BibleStoryCore

/// A deterministic three-page story used across player and library tests.
/// Page index 1 is a wonder pause.
enum StoryFixtures {
    static let story = Story(
        id: UUID(uuidString: "0A000000-0000-4000-8000-000000000001")!,
        title: "Test Story",
        coverImageName: "test_cover",
        estimatedMinutes: 3,
        pages: [
            StoryPage(
                id: UUID(uuidString: "0A000000-0000-4000-8000-000000000010")!,
                imageName: "p1",
                narrationText: "Page one.",
                audioAssetName: "p1_audio",
                isWonderPause: false
            ),
            StoryPage(
                id: UUID(uuidString: "0A000000-0000-4000-8000-000000000011")!,
                imageName: "p2",
                narrationText: "Page two.",
                audioAssetName: "p2_audio",
                isWonderPause: true
            ),
            StoryPage(
                id: UUID(uuidString: "0A000000-0000-4000-8000-000000000012")!,
                imageName: "p3",
                narrationText: "Page three.",
                audioAssetName: "p3_audio",
                isWonderPause: false
            ),
        ]
    )
}
```

- [ ] **Step 3: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/StoryPlayerModelTests.swift`:
```swift
import XCTest
@testable import BibleStoryCore

@MainActor
final class StoryPlayerModelTests: XCTestCase {
    func testStartsAtFirstPageNotPlaying() {
        let model = StoryPlayerModel(story: StoryFixtures.story, player: MockNarrationPlayer())
        XCTAssertEqual(model.currentPageIndex, 0)
        XCTAssertFalse(model.isPlaying)
        XCTAssertFalse(model.finished)
    }

    func testCurrentPageReflectsIndex() {
        let model = StoryPlayerModel(story: StoryFixtures.story, player: MockNarrationPlayer())
        XCTAssertEqual(model.currentPage, StoryFixtures.story.pages[0])
    }
}
```

- [ ] **Step 4: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "StoryPlayerModelTests"
```
Expected: BUILD FAILURE — `cannot find 'StoryPlayerModel' in scope` (and `NarrationPlayer`).

- [ ] **Step 5: Implement the `NarrationPlayer` protocol**

Create `app/BibleStoryCore/Sources/BibleStoryCore/NarrationPlayer.swift`:
```swift
/// Plays pre-rendered narration audio. The core package depends only on this
/// protocol so it stays testable; the AVFoundation implementation lives in the
/// app target.
public protocol NarrationPlayer: Sendable {
    /// Starts playing the named bundled audio asset. Returns promptly (playback
    /// continues asynchronously); a no-op if the asset is missing.
    func play(assetNamed name: String) async
    /// Pauses playback, keeping position so `play` can resume.
    func pause() async
    /// Stops playback and releases the current audio.
    func stop() async
}
```

- [ ] **Step 6: Implement the `StoryPlayerModel` skeleton**

Create `app/BibleStoryCore/Sources/BibleStoryCore/StoryPlayerModel.swift`:
```swift
import Observation

/// Drives one story session: which page is showing, whether narration is
/// playing, and whether the story is finished. Page turns and playback commands
/// are added in later tasks.
@MainActor
@Observable
public final class StoryPlayerModel {
    public let story: Story
    public private(set) var currentPageIndex: Int = 0
    public private(set) var isPlaying: Bool = false
    public private(set) var finished: Bool = false

    private let player: NarrationPlayer

    public init(story: Story, player: NarrationPlayer) {
        self.story = story
        self.player = player
    }

    /// The page currently shown. Always a valid index into `story.pages`.
    public var currentPage: StoryPage {
        story.pages[currentPageIndex]
    }
}
```

- [ ] **Step 7: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "StoryPlayerModelTests"
```
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): add NarrationPlayer protocol and StoryPlayerModel initial state"
```

---

### Task 4: `StoryPlayerModel` page turns — `advance()`, `back()`, `finished`, `atWonderPause`

Adds page navigation. Turning to a page starts that page's narration (audio-first). Advancing off the last page ends the story (`finished`), stops audio, and holds the index at the last page. `atWonderPause` reflects the current page.

**Files:**
- Modify: `app/BibleStoryCore/Sources/BibleStoryCore/StoryPlayerModel.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/StoryPlayerModelTests.swift`

**Interfaces:**
- Consumes: `StoryPlayerModel`, `NarrationPlayer`, `MockNarrationPlayer`, `StoryFixtures` (Task 3).
- Produces on `StoryPlayerModel`: `public func advance() async`, `public func back() async`, `public var atWonderPause: Bool`. `advance`/`back` play the resulting page's `audioAssetName`; advancing past the last page sets `finished = true`, `isPlaying = false`, and calls `player.stop()`; `back` clears `finished`.

- [ ] **Step 1: Write the failing test**

Add to `StoryPlayerModelTests` in `app/BibleStoryCore/Tests/BibleStoryCoreTests/StoryPlayerModelTests.swift`:
```swift
    func testAdvanceMovesToNextPageAndPlaysIt() async {
        let player = MockNarrationPlayer()
        let model = StoryPlayerModel(story: StoryFixtures.story, player: player)

        await model.advance()

        XCTAssertEqual(model.currentPageIndex, 1)
        XCTAssertEqual(player.playedAssets, ["p2_audio"])
        XCTAssertTrue(model.atWonderPause)   // page index 1 is a wonder pause
    }

    func testBackMovesToPreviousPage() async {
        let model = StoryPlayerModel(story: StoryFixtures.story, player: MockNarrationPlayer())

        await model.advance()
        await model.advance()
        XCTAssertEqual(model.currentPageIndex, 2)

        await model.back()
        XCTAssertEqual(model.currentPageIndex, 1)
    }

    func testBackAtFirstPageIsNoOp() async {
        let model = StoryPlayerModel(story: StoryFixtures.story, player: MockNarrationPlayer())
        await model.back()
        XCTAssertEqual(model.currentPageIndex, 0)
    }

    func testAdvancingPastLastPageFinishes() async {
        let player = MockNarrationPlayer()
        let model = StoryPlayerModel(story: StoryFixtures.story, player: player)

        await model.advance()   // -> 1
        await model.advance()   // -> 2 (last)
        await model.advance()   // -> finished

        XCTAssertTrue(model.finished)
        XCTAssertEqual(model.currentPageIndex, 2)   // held at last page
        XCTAssertFalse(model.isPlaying)
        XCTAssertEqual(player.stopCount, 1)
    }

    func testBackClearsFinished() async {
        let model = StoryPlayerModel(story: StoryFixtures.story, player: MockNarrationPlayer())
        await model.advance()
        await model.advance()
        await model.advance()   // finished
        XCTAssertTrue(model.finished)

        await model.back()

        XCTAssertFalse(model.finished)
        XCTAssertEqual(model.currentPageIndex, 1)
    }

    func testAtWonderPauseIsFalseOnPlainPages() {
        let model = StoryPlayerModel(story: StoryFixtures.story, player: MockNarrationPlayer())
        XCTAssertFalse(model.atWonderPause)   // page 0 is not a wonder pause
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "StoryPlayerModelTests"
```
Expected: BUILD FAILURE — `value of type 'StoryPlayerModel' has no member 'advance'`.

- [ ] **Step 3: Implement page turns**

Update `app/BibleStoryCore/Sources/BibleStoryCore/StoryPlayerModel.swift` to the full file below:
```swift
import Observation

/// Drives one story session: which page is showing, whether narration is
/// playing, and whether the story is finished.
@MainActor
@Observable
public final class StoryPlayerModel {
    public let story: Story
    public private(set) var currentPageIndex: Int = 0
    public private(set) var isPlaying: Bool = false
    public private(set) var finished: Bool = false

    private let player: NarrationPlayer

    public init(story: Story, player: NarrationPlayer) {
        self.story = story
        self.player = player
    }

    /// The page currently shown. Always a valid index into `story.pages`.
    public var currentPage: StoryPage {
        story.pages[currentPageIndex]
    }

    /// True when the current page invites the child to wonder aloud.
    public var atWonderPause: Bool {
        currentPage.isWonderPause
    }

    /// Turns to the next page and plays it. On the last page, ends the story.
    public func advance() async {
        guard !finished else { return }
        if currentPageIndex + 1 < story.pages.count {
            currentPageIndex += 1
            await playCurrentPage()
        } else {
            finished = true
            isPlaying = false
            await player.stop()
        }
    }

    /// Turns back to the previous page and plays it. No-op on the first page.
    public func back() async {
        guard currentPageIndex > 0 else { return }
        finished = false
        currentPageIndex -= 1
        await playCurrentPage()
    }

    private func playCurrentPage() async {
        isPlaying = true
        await player.play(assetNamed: currentPage.audioAssetName)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "StoryPlayerModelTests"
```
Expected: PASS — all page-turn tests green.

- [ ] **Step 5: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): add page turns, finished, and wonder-pause to StoryPlayerModel"
```

---

### Task 5: `StoryPlayerModel` playback controls — `play()`, `pause()`, `replayPage()`

Adds the pause/replay/continue controls from PRD §5.2, wired to the `NarrationPlayer`. These use only the shared `NarrationPlayer` protocol methods.

**Files:**
- Modify: `app/BibleStoryCore/Sources/BibleStoryCore/StoryPlayerModel.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/StoryPlayerModelTests.swift`

**Interfaces:**
- Consumes: `StoryPlayerModel`, `MockNarrationPlayer`, `StoryFixtures` (Tasks 3–4).
- Produces on `StoryPlayerModel`: `public func play() async` (plays the current page; `isPlaying = true`), `public func pause() async` (`player.pause()`; `isPlaying = false`), `public func replayPage() async` (plays the current page again from the start).

- [ ] **Step 1: Write the failing test**

Add to `StoryPlayerModelTests`:
```swift
    func testPlayPlaysCurrentPage() async {
        let player = MockNarrationPlayer()
        let model = StoryPlayerModel(story: StoryFixtures.story, player: player)

        await model.play()

        XCTAssertEqual(player.playedAssets, ["p1_audio"])
        XCTAssertTrue(model.isPlaying)
    }

    func testPausePausesPlayer() async {
        let player = MockNarrationPlayer()
        let model = StoryPlayerModel(story: StoryFixtures.story, player: player)

        await model.play()
        await model.pause()

        XCTAssertEqual(player.pauseCount, 1)
        XCTAssertFalse(model.isPlaying)
    }

    func testReplayPageReplaysCurrentPage() async {
        let player = MockNarrationPlayer()
        let model = StoryPlayerModel(story: StoryFixtures.story, player: player)

        await model.play()
        await model.replayPage()

        XCTAssertEqual(player.playedAssets, ["p1_audio", "p1_audio"])
        XCTAssertTrue(model.isPlaying)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "StoryPlayerModelTests"
```
Expected: BUILD FAILURE — `value of type 'StoryPlayerModel' has no member 'play'`.

- [ ] **Step 3: Implement the playback controls**

Update `app/BibleStoryCore/Sources/BibleStoryCore/StoryPlayerModel.swift` to the full file below:
```swift
import Observation

/// Drives one story session: which page is showing, whether narration is
/// playing, and whether the story is finished.
@MainActor
@Observable
public final class StoryPlayerModel {
    public let story: Story
    public private(set) var currentPageIndex: Int = 0
    public private(set) var isPlaying: Bool = false
    public private(set) var finished: Bool = false

    private let player: NarrationPlayer

    public init(story: Story, player: NarrationPlayer) {
        self.story = story
        self.player = player
    }

    /// The page currently shown. Always a valid index into `story.pages`.
    public var currentPage: StoryPage {
        story.pages[currentPageIndex]
    }

    /// True when the current page invites the child to wonder aloud.
    public var atWonderPause: Bool {
        currentPage.isWonderPause
    }

    /// Starts (or resumes) narration of the current page.
    public func play() async {
        await playCurrentPage()
    }

    /// Pauses narration, keeping the page.
    public func pause() async {
        isPlaying = false
        await player.pause()
    }

    /// Plays the current page's narration again from the start.
    public func replayPage() async {
        await playCurrentPage()
    }

    /// Turns to the next page and plays it. On the last page, ends the story.
    public func advance() async {
        guard !finished else { return }
        if currentPageIndex + 1 < story.pages.count {
            currentPageIndex += 1
            await playCurrentPage()
        } else {
            finished = true
            isPlaying = false
            await player.stop()
        }
    }

    /// Turns back to the previous page and plays it. No-op on the first page.
    public func back() async {
        guard currentPageIndex > 0 else { return }
        finished = false
        currentPageIndex -= 1
        await playCurrentPage()
    }

    private func playCurrentPage() async {
        isPlaying = true
        await player.play(assetNamed: currentPage.audioAssetName)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "StoryPlayerModelTests"
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): add play/pause/replayPage controls to StoryPlayerModel"
```

---

### Task 6: `StoryLibrary` + `StoryProgressStore` protocols + `LibraryModel`

Adds the library-loading and progress-persistence seams and the `LibraryModel` that presents stories with completed markers (PRD B1, B4).

**Files:**
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/StoryLibrary.swift`
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/StoryProgressStore.swift`
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/LibraryModel.swift`
- Modify: `app/BibleStoryCore/Tests/BibleStoryCoreTests/TestDoubles.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/LibraryModelTests.swift`

**Interfaces:**
- Consumes: `Story` (Task 1).
- Produces:
  - `public protocol StoryLibrary: Sendable` with `func allStories() -> [Story]` and `func story(id: UUID) -> Story?`.
  - `public protocol StoryProgressStore: Sendable` with `func markCompleted(storyID: UUID, childID: UUID) async` and `func completedStoryIDs(childID: UUID) async -> Set<UUID>`.
  - `@MainActor @Observable public final class LibraryModel` with `public init(library: StoryLibrary, progress: StoryProgressStore, childID: UUID)`, `public private(set) var stories: [Story]`, `public private(set) var completedStoryIDs: Set<UUID>`, `public func load() async`, `public func markCompleted(storyID: UUID) async`, `public func isCompleted(_ storyID: UUID) -> Bool`.
  - Test doubles `InMemoryStoryLibrary` (struct) and `InMemoryStoryProgressStore` (`@MainActor` class).

- [ ] **Step 1: Add the in-memory test doubles**

Append to `app/BibleStoryCore/Tests/BibleStoryCoreTests/TestDoubles.swift`:
```swift

/// A synchronous, immutable in-memory library. Implicitly `Sendable`
/// (all stored state is `Sendable` and immutable).
struct InMemoryStoryLibrary: StoryLibrary {
    let stories: [Story]

    func allStories() -> [Story] { stories }
    func story(id: UUID) -> Story? { stories.first { $0.id == id } }
}

/// An in-memory progress store. `@MainActor` for a clean `Sendable` conformance
/// with `async` requirements (same pattern as `MockNarrationPlayer`).
@MainActor
final class InMemoryStoryProgressStore: StoryProgressStore {
    private var completed: [UUID: Set<UUID>] = [:]

    nonisolated init() {}

    func markCompleted(storyID: UUID, childID: UUID) async {
        completed[childID, default: []].insert(storyID)
    }

    func completedStoryIDs(childID: UUID) async -> Set<UUID> {
        completed[childID] ?? []
    }
}
```
Note: `TestDoubles.swift` uses `@testable import BibleStoryCore`; add `import Foundation` at the top of the file if it is not already imported (needed for `UUID`).

- [ ] **Step 2: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/LibraryModelTests.swift`:
```swift
import XCTest
import Foundation
@testable import BibleStoryCore

@MainActor
final class LibraryModelTests: XCTestCase {
    private let childID = UUID(uuidString: "0C000000-0000-4000-8000-000000000001")!

    private func makeModel(
        progress: InMemoryStoryProgressStore = InMemoryStoryProgressStore()
    ) -> LibraryModel {
        LibraryModel(
            library: InMemoryStoryLibrary(stories: [StoryFixtures.story]),
            progress: progress,
            childID: childID
        )
    }

    func testLoadPopulatesStories() async {
        let model = makeModel()
        await model.load()
        XCTAssertEqual(model.stories, [StoryFixtures.story])
    }

    func testLoadReadsCompletedMarkers() async {
        let progress = InMemoryStoryProgressStore()
        await progress.markCompleted(storyID: StoryFixtures.story.id, childID: childID)

        let model = makeModel(progress: progress)
        await model.load()

        XCTAssertTrue(model.isCompleted(StoryFixtures.story.id))
        XCTAssertEqual(model.completedStoryIDs, [StoryFixtures.story.id])
    }

    func testMarkCompletedUpdatesAndPersists() async {
        let progress = InMemoryStoryProgressStore()
        let model = makeModel(progress: progress)
        await model.load()
        XCTAssertFalse(model.isCompleted(StoryFixtures.story.id))

        await model.markCompleted(storyID: StoryFixtures.story.id)

        XCTAssertTrue(model.isCompleted(StoryFixtures.story.id))
        // Persisted to the shared store: a fresh model sees the marker.
        let fresh = makeModel(progress: progress)
        await fresh.load()
        XCTAssertTrue(fresh.isCompleted(StoryFixtures.story.id))
    }
}
```

- [ ] **Step 3: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "LibraryModelTests"
```
Expected: BUILD FAILURE — `cannot find 'LibraryModel' in scope` (and the two protocols).

- [ ] **Step 4: Implement the `StoryLibrary` protocol**

Create `app/BibleStoryCore/Sources/BibleStoryCore/StoryLibrary.swift`:
```swift
import Foundation

/// Loads the bundled, vetted stories. The concrete bundle-backed implementation
/// lives in the app target.
public protocol StoryLibrary: Sendable {
    func allStories() -> [Story]
    func story(id: UUID) -> Story?
}
```

- [ ] **Step 5: Implement the `StoryProgressStore` protocol**

Create `app/BibleStoryCore/Sources/BibleStoryCore/StoryProgressStore.swift`:
```swift
import Foundation

/// Persists which stories a child has completed. The concrete implementation
/// (device-local storage; CloudKit sync arrives in P6) lives in the app target.
public protocol StoryProgressStore: Sendable {
    func markCompleted(storyID: UUID, childID: UUID) async
    func completedStoryIDs(childID: UUID) async -> Set<UUID>
}
```

- [ ] **Step 6: Implement the `LibraryModel`**

Create `app/BibleStoryCore/Sources/BibleStoryCore/LibraryModel.swift`:
```swift
import Foundation
import Observation

/// Presents the story library for one child, with completed markers.
@MainActor
@Observable
public final class LibraryModel {
    public private(set) var stories: [Story] = []
    public private(set) var completedStoryIDs: Set<UUID> = []

    private let library: StoryLibrary
    private let progress: StoryProgressStore
    private let childID: UUID

    public init(library: StoryLibrary, progress: StoryProgressStore, childID: UUID) {
        self.library = library
        self.progress = progress
        self.childID = childID
    }

    /// Loads stories and this child's completed markers.
    public func load() async {
        stories = library.allStories()
        completedStoryIDs = await progress.completedStoryIDs(childID: childID)
    }

    /// Marks a story completed for this child and reflects it locally.
    public func markCompleted(storyID: UUID) async {
        await progress.markCompleted(storyID: storyID, childID: childID)
        completedStoryIDs.insert(storyID)
    }

    /// Whether this child has completed the given story.
    public func isCompleted(_ storyID: UUID) -> Bool {
        completedStoryIDs.contains(storyID)
    }
}
```

- [ ] **Step 7: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "LibraryModelTests"
```
Expected: PASS.

- [ ] **Step 8: Run the full core suite to confirm nothing regressed**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore
```
Expected: PASS — `StoryTests`, `StoryDecoderTests`, `StoryPlayerModelTests`, `LibraryModelTests`, and P1's `ZoneTests` / `AppModelTests` all green.

- [ ] **Step 9: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): add StoryLibrary, StoryProgressStore, and LibraryModel"
```

---

### Task 7: Content pipeline — sample story JSON + bundled loading glue

Commits the real "David & Goliath" story JSON (one wonder-pause page), wires it into the app bundle via `project.yml`, and adds the app-target glue that loads it: `BundledStoryLibrary` (decodes via `StoryDecoder`) and `UserDefaultsStoryProgressStore` (device-local completion). Verified by build + a JSON schema check. Real illustration art and premium-TTS narration audio are a content-ops task, OUT of code scope; only placeholder asset *names* are committed.

**Files:**
- Create: `app/BibleStory/BibleStory/Content/stories.json`
- Modify: `app/BibleStory/project.yml`
- Create: `app/BibleStory/BibleStory/BundledStoryLibrary.swift`
- Create: `app/BibleStory/BibleStory/UserDefaultsStoryProgressStore.swift`

**Interfaces:**
- Consumes: `StoryDecoder`, `Story`, `StoryLibrary`, `StoryProgressStore` (from `BibleStoryCore`).
- Produces: `struct BundledStoryLibrary: StoryLibrary` (loads `stories.json` from the app bundle, decoding through the validating `StoryDecoder`) and `struct UserDefaultsStoryProgressStore: StoryProgressStore` (`@unchecked Sendable`, `UserDefaults`-backed).

- [ ] **Step 1: Commit the sample story JSON**

Create `app/BibleStory/BibleStory/Content/stories.json`:
```json
{
  "schemaVersion": 1,
  "stories": [
    {
      "id": "7F3A2B1C-0D4E-4A5F-9B6C-1E2D3F4A5B6C",
      "title": "David & Goliath",
      "coverImageName": "david_goliath_cover",
      "estimatedMinutes": 6,
      "pages": [
        {
          "id": "A1B2C3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D",
          "imageName": "david_goliath_p1",
          "narrationText": "Long ago, in the green hills where sheep wandered and little streams sparkled, there lived a boy named David. He was the youngest of many brothers. His brothers were tall and strong, but David spent his days out in the fields, watching over his father's sheep. He was not very big at all. Still, David had a brave and gentle heart, and he loved to sing quiet songs to God under the wide open sky.",
          "audioAssetName": "david_goliath_p1_narration",
          "isWonderPause": false
        },
        {
          "id": "B2C3D4E5-F6A7-4B8C-9D0E-1F2A3B4C5D6E",
          "imageName": "david_goliath_p2",
          "narrationText": "One day, David's father asked him to carry some food to his older brothers, who were far away with the king's army. When David reached the camp, he heard shouting rolling across the valley. On the other side stood an enemy army, and stepping out in front of them was a giant of a man named Goliath. He was taller than anyone David had ever seen, wrapped in heavy armor that clanked and rattled with every step.",
          "audioAssetName": "david_goliath_p2_narration",
          "isWonderPause": false
        },
        {
          "id": "C3D4E5F6-A7B8-4C9D-8E0F-2A3B4C5D6E7F",
          "imageName": "david_goliath_p3",
          "narrationText": "Every morning and every evening, Goliath stomped into the valley and roared, \"Send someone to face me!\" And every soldier, even the biggest and the bravest, trembled and hid away. David looked at the frightened men, and then up, up, up at the towering giant. I wonder what you would be feeling if you were standing in that valley.",
          "audioAssetName": "david_goliath_p3_narration",
          "isWonderPause": true
        },
        {
          "id": "D4E5F6A7-B8C9-4D0E-9F1A-3B4C5D6E7F80",
          "imageName": "david_goliath_p4",
          "narrationText": "David went to the king and said he would go. The king shook his head. \"You are only a boy,\" he said. But David remembered all the times God had helped him keep his little sheep safe, even from lions and bears. God had helped him before, David said, and God would help him now. So he picked five smooth stones from the stream, took his shepherd's sling, and walked out toward the giant.",
          "audioAssetName": "david_goliath_p4_narration",
          "isWonderPause": false
        },
        {
          "id": "E5F6A7B8-C9D0-4E1F-8A2B-4C5D6E7F8091",
          "imageName": "david_goliath_p5",
          "narrationText": "Goliath laughed a great booming laugh when he saw such a small boy coming. But David was not trusting in his own size or strength. He called out that he came in the name of the Lord. Then he placed one stone in his sling, swung it round and round and round, and let it fly. The stone sailed straight and true, and the mighty giant came tumbling down to the ground.",
          "audioAssetName": "david_goliath_p5_narration",
          "isWonderPause": false
        },
        {
          "id": "F6A7B8C9-D0E1-4F2A-9B3C-5D6E7F809102",
          "imageName": "david_goliath_p6",
          "narrationText": "The soldiers could hardly believe their eyes. The giant everyone had feared was beaten by a shepherd boy who trusted God with all his heart. David was not the biggest or the strongest. But he was brave, because he knew he was never alone. And that is a story people have loved to tell and remember ever since.",
          "audioAssetName": "david_goliath_p6_narration",
          "isWonderPause": false
        }
      ]
    }
  ]
}
```

- [ ] **Step 2: Verify the committed JSON matches the schema**

Run (from repo root):
```bash
python3 - <<'PY'
import json
d = json.load(open("app/BibleStory/BibleStory/Content/stories.json"))
assert d["schemaVersion"] == 1, "schemaVersion must be 1"
stories = d["stories"]
assert len(stories) >= 1, "need at least one story"
s = stories[0]
assert s["id"] and s["title"] and s["coverImageName"] and s["pages"], "story fields present"
assert isinstance(s["estimatedMinutes"], int), "estimatedMinutes is an int"
words = sum(len(p["narrationText"].split()) for p in s["pages"])
assert 400 <= words <= 700, f"narration should be 400-700 words, got {words}"
assert sum(1 for p in s["pages"] if p["isWonderPause"]) == 1, "exactly one wonder pause"
for p in s["pages"]:
    assert p["id"] and p["imageName"] and p["narrationText"] and p["audioAssetName"], "page fields present"
print(f"stories.json OK: '{s['title']}', {len(s['pages'])} pages, {words} words")
PY
```
Expected: `stories.json OK: 'David & Goliath', 6 pages, <N> words` with `400 <= N <= 700`. (If `python3` is unavailable, use `plutil -lint app/BibleStory/BibleStory/Content/stories.json` for a well-formedness check; the full schema is exercised at runtime in Task 8 and by `StoryDecoderTests`.)

- [ ] **Step 3: Wire the Content folder into the app target as a resource**

Edit `app/BibleStory/project.yml`. Replace the `sources` block of the `BibleStory` target:
```yaml
    sources:
      - path: BibleStory
```
with:
```yaml
    sources:
      - path: BibleStory
        excludes:
          - "Content/**"
      - path: BibleStory/Content
        buildPhase: resources
```
This keeps the recursive Swift-source scan but routes `Content/` (the story JSON, and later the illustration/audio assets) explicitly into the app's Resources build phase without double-adding it.

- [ ] **Step 4: Write `BundledStoryLibrary`**

Create `app/BibleStory/BibleStory/BundledStoryLibrary.swift`:
```swift
import Foundation
import BibleStoryCore

/// Loads the vetted stories bundled in the app (`stories.json`), decoding them
/// through the validating `StoryDecoder`.
///
/// "Verifying asset names" means the decoder guarantees every referenced
/// illustration/audio name is present and non-empty. Verifying that the actual
/// art/audio *files* exist is deferred until real assets are produced by
/// content-ops (PRD FR-1) — until then the names are placeholders and the views
/// / audio player fall back gracefully.
struct BundledStoryLibrary: StoryLibrary {
    private let stories: [Story]

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "stories", withExtension: "json") else {
            assertionFailure("stories.json is missing from the app bundle")
            self.stories = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            self.stories = try StoryDecoder.decode(data)
        } catch {
            assertionFailure("Failed to decode stories.json: \(error)")
            self.stories = []
        }
    }

    func allStories() -> [Story] { stories }
    func story(id: UUID) -> Story? { stories.first { $0.id == id } }
}
```

- [ ] **Step 5: Write `UserDefaultsStoryProgressStore`**

Create `app/BibleStory/BibleStory/UserDefaultsStoryProgressStore.swift`:
```swift
import Foundation
import BibleStoryCore

/// Device-local persistence of completed stories per child, backed by
/// `UserDefaults`. Cross-device sync via CloudKit is a P6 concern.
/// `@unchecked Sendable`: `UserDefaults` is documented thread-safe.
struct UserDefaultsStoryProgressStore: StoryProgressStore, @unchecked Sendable {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func key(_ childID: UUID) -> String {
        "completedStories.\(childID.uuidString)"
    }

    func markCompleted(storyID: UUID, childID: UUID) async {
        var ids = defaults.stringArray(forKey: key(childID)) ?? []
        let value = storyID.uuidString
        if !ids.contains(value) {
            ids.append(value)
            defaults.set(ids, forKey: key(childID))
        }
    }

    func completedStoryIDs(childID: UUID) async -> Set<UUID> {
        let ids = defaults.stringArray(forKey: key(childID)) ?? []
        return Set(ids.compactMap(UUID.init(uuidString:)))
    }
}
```

- [ ] **Step 6: Regenerate the Xcode project**

Run (from `app/BibleStory/`):
```bash
xcodegen generate
```
Expected: `Loaded project ... Created project at ...BibleStory.xcodeproj`.

- [ ] **Step 7: Build for the Simulator**

Run (from `app/BibleStory/`):
```bash
xcodebuild -project BibleStory.xcodeproj -scheme BibleStory \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: `** BUILD SUCCEEDED **`. (If the named simulator doesn't exist, list options with `xcrun simctl list devices available` and substitute a name.)

- [ ] **Step 8: Commit**

```bash
git add app/BibleStory/BibleStory/Content app/BibleStory/project.yml \
  app/BibleStory/BibleStory/BundledStoryLibrary.swift \
  app/BibleStory/BibleStory/UserDefaultsStoryProgressStore.swift \
  app/BibleStory/BibleStory.xcodeproj
git commit -m "feat(app): add David & Goliath story JSON + bundled content loading"
```

---

### Task 8: SwiftUI Library + Story Player, wired as the child-zone home

Adds the AVFoundation narration player and the two child-zone screens, and replaces P1's "Story Library" placeholder in `ChildZoneView` with the real `LibraryView` (keeping the gated parent-entry button). Verified by build + a manual Simulator checklist. Audio assets are placeholders, so narration is silent for now; controls, page turns, the wonder-pause cue, completion/reward, and completed markers are all exercisable.

**Files:**
- Create: `app/BibleStory/BibleStory/AVFoundationNarrationPlayer.swift`
- Create: `app/BibleStory/BibleStory/LibraryView.swift`
- Create: `app/BibleStory/BibleStory/StoryPlayerView.swift`
- Modify: `app/BibleStory/BibleStory/ChildZoneView.swift`

**Interfaces:**
- Consumes: `NarrationPlayer`, `StoryLibrary`, `StoryProgressStore`, `Story`, `LibraryModel`, `StoryPlayerModel`, `AppModel` (from `BibleStoryCore`), and `BundledStoryLibrary`, `UserDefaultsStoryProgressStore` (Task 7).
- Produces: `AVFoundationNarrationPlayer: NarrationPlayer` (app target), `LibraryView`, `StoryPlayerView`, and a `ChildZoneView` whose body hosts `LibraryView`.

- [ ] **Step 1: Write `AVFoundationNarrationPlayer`**

Create `app/BibleStory/BibleStory/AVFoundationNarrationPlayer.swift`:
```swift
import AVFoundation
import BibleStoryCore

/// Plays bundled narration audio via `AVAudioPlayer`. If the named asset is not
/// bundled (placeholder content), playback is a silent no-op — never a crash.
/// `@MainActor` for a clean `Sendable` conformance to `NarrationPlayer`.
@MainActor
final class AVFoundationNarrationPlayer: NarrationPlayer {
    private var player: AVAudioPlayer?
    private var currentAsset: String?

    private static let audioExtensions = ["m4a", "mp3", "caf", "aac"]

    func play(assetNamed name: String) async {
        // Resume the same paused asset instead of restarting it.
        if name == currentAsset, let player, !player.isPlaying {
            player.play()
            return
        }

        guard let url = Self.url(for: name) else {
            currentAsset = name
            player = nil
            return   // placeholder asset not bundled yet — silent no-op
        }

        configureSession()
        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer
            currentAsset = name
        } catch {
            player = nil
        }
    }

    func pause() async { player?.pause() }

    func stop() async {
        player?.stop()
        player = nil
        currentAsset = nil
    }

    private static func url(for name: String) -> URL? {
        // Allow either a bare name or a name that already carries an extension.
        if let direct = Bundle.main.url(forResource: name, withExtension: nil) {
            return direct
        }
        for ext in audioExtensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }

    private func configureSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}
```

- [ ] **Step 2: Write `LibraryView`**

Create `app/BibleStory/BibleStory/LibraryView.swift`:
```swift
import SwiftUI
import BibleStoryCore

/// The child-zone home: friendly illustrated tiles with completed markers.
/// Tapping a tile opens the full-screen Story Player.
struct LibraryView: View {
    @State private var model: LibraryModel
    @State private var selectedStory: Story?

    init(library: StoryLibrary, progress: StoryProgressStore, childID: UUID) {
        _model = State(initialValue: LibraryModel(
            library: library, progress: progress, childID: childID
        ))
    }

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 20)]

    var body: some View {
        ScrollView {
            Text("Story Time")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.horizontal, .top])

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(model.stories) { story in
                    Button {
                        selectedStory = story
                    } label: {
                        StoryTile(story: story, completed: model.isCompleted(story.id))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .task { await model.load() }
        .fullScreenCover(item: $selectedStory) { story in
            StoryPlayerView(story: story) {
                Task { await model.markCompleted(storyID: story.id) }
                selectedStory = nil
            }
        }
    }
}

/// A single story tile. Shows the illustration if it exists in the asset
/// catalog, otherwise a friendly gradient placeholder, with a completed badge.
private struct StoryTile: View {
    let story: Story
    let completed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                cover
                    .frame(height: 140)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                if completed {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .green)
                        .padding(8)
                        .accessibilityLabel("Completed")
                }
            }
            Text(story.title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text("\(story.estimatedMinutes) min")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var cover: some View {
        if let image = UIImage(named: story.coverImageName) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            ZStack {
                LinearGradient(
                    colors: [.indigo, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "book.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }
}
```

- [ ] **Step 3: Write `StoryPlayerView`**

Create `app/BibleStory/BibleStory/StoryPlayerView.swift`:
```swift
import SwiftUI
import BibleStoryCore

/// The full-bleed Story Player: illustration + narration text, audio controls
/// (back / play-pause / replay / continue), a gentle wonder-pause cue, and a
/// completion reward. Calls `onFinished` when the child finishes or closes.
struct StoryPlayerView: View {
    @State private var model: StoryPlayerModel
    private let onFinished: () -> Void

    init(story: Story, onFinished: @escaping () -> Void) {
        _model = State(initialValue: StoryPlayerModel(
            story: story, player: AVFoundationNarrationPlayer()
        ))
        self.onFinished = onFinished
    }

    var body: some View {
        ZStack {
            if model.finished {
                CompletionRewardView(onDone: onFinished)
            } else {
                illustration.ignoresSafeArea()
                VStack {
                    closeButton
                    Spacer()
                    if model.atWonderPause {
                        WonderPauseCue()
                            .transition(.scale.combined(with: .opacity))
                    }
                    narrationCard
                    controlBar
                }
                .padding()
            }
        }
        .animation(.easeInOut, value: model.atWonderPause)
        .task { await model.play() }
    }

    @ViewBuilder
    private var illustration: some View {
        if let image = UIImage(named: model.currentPage.imageName) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            LinearGradient(
                colors: [.blue.opacity(0.7), .indigo],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var closeButton: some View {
        HStack {
            Spacer()
            Button {
                onFinished()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .accessibilityLabel("Close story")
        }
    }

    private var narrationCard: some View {
        Text(model.currentPage.narrationText)
            .font(.title3)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var controlBar: some View {
        HStack(spacing: 36) {
            Button {
                Task { await model.back() }
            } label: {
                Image(systemName: "backward.end.fill")
            }
            .disabled(model.currentPageIndex == 0)
            .accessibilityLabel("Previous page")

            Button {
                Task {
                    if model.isPlaying {
                        await model.pause()
                    } else {
                        await model.play()
                    }
                }
            } label: {
                Image(systemName: model.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
            }
            .accessibilityLabel(model.isPlaying ? "Pause" : "Play")

            Button {
                Task { await model.replayPage() }
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .accessibilityLabel("Replay page")

            Button {
                Task { await model.advance() }
            } label: {
                Image(systemName: "forward.end.fill")
            }
            .accessibilityLabel("Continue")
        }
        .font(.title)
        .foregroundStyle(.white)
        .padding()
    }
}

/// A gentle, non-blocking cue inviting the child to wonder aloud.
/// The ask-a-question loop itself is wired in P4.
private struct WonderPauseCue: View {
    var body: some View {
        Label("I wonder…", systemImage: "sparkles")
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.yellow.opacity(0.9), in: Capsule())
            .foregroundStyle(.black)
            .accessibilityLabel("A good place to wonder")
    }
}

/// Warm close + simple reward cue shown when the story finishes.
private struct CompletionRewardView: View {
    let onDone: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.orange, .pink],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "star.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.yellow)
                Text("Great job!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                Text("You finished the story.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.95))
                Button {
                    onDone()
                } label: {
                    Text("Back to Stories")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.white, in: Capsule())
                }
            }
            .padding()
        }
    }
}
```

- [ ] **Step 4: Wire `LibraryView` into `ChildZoneView`**

Replace `app/BibleStory/BibleStory/ChildZoneView.swift` with the full file below. The gated parent-entry button from P1 is preserved; only the "Story Library" placeholder text is replaced by the real `LibraryView`.
```swift
import SwiftUI
import BibleStoryCore

/// The child experience: the Story Library, with the gated parent-entry button
/// overlaid. The only way out to the parent area is through that gated button.
struct ChildZoneView: View {
    let appModel: AppModel

    /// The active child. P2 (accounts/onboarding) will supply the real profile
    /// id; for now a fixed device-local id keeps completion markers stable.
    private static let activeChildID = UUID(
        uuidString: "0A11CE00-0000-4000-8000-000000000001"
    )!

    @State private var library = BundledStoryLibrary()
    @State private var progress = UserDefaultsStoryProgressStore()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LibraryView(
                library: library,
                progress: progress,
                childID: Self.activeChildID
            )

            Button {
                Task { await appModel.enterParentZone() }
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.title2)
                    .padding()
            }
            .accessibilityLabel("Parent area")
            .disabled(appModel.isAuthenticating)
        }
    }
}
```

- [ ] **Step 5: Regenerate the Xcode project**

Run (from `app/BibleStory/`):
```bash
xcodegen generate
```
Expected: `Created project at ...BibleStory.xcodeproj`.

- [ ] **Step 6: Build for the Simulator**

Run (from `app/BibleStory/`):
```bash
xcodebuild -project BibleStory.xcodeproj -scheme BibleStory \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 7: Manual run verification**

Run the app in the Simulator (Xcode ▸ Run, or `xcodebuild ... test`-free launch). Verify this checklist:
1. App launches into the **child zone**: a "Story Time" library showing a **David & Goliath** tile (gradient placeholder cover + "6 min"), with the small parent icon still in the top-right corner. The tile has **no** completed badge on first launch.
2. Tap the tile → a **full-screen Story Player** appears: a full-bleed illustration placeholder, the page-1 narration text in a card, and the control bar (previous / play-pause / replay / continue). Narration is silent (placeholder audio) — expected.
3. Tap **continue** to page through. The controls respond; **previous** is disabled on page 1.
4. On **page 3** (the wonder-pause page), the gentle **"I wonder…"** cue appears above the narration card.
5. Tap **continue** past the last page → the **"Great job!"** reward screen appears.
6. Tap **Back to Stories** → return to the library. The David & Goliath tile now shows the **green completed badge**.
7. Stop and relaunch the app → the completed badge **persists** (UserDefaults-backed progress).
8. Tap the parent icon → Face ID prompt (from P1) still works and the kid-mode lock is intact: a matching face opens "Parent Dashboard", a non-matching face keeps you in the child zone.

- [ ] **Step 8: Commit**

```bash
git add app/BibleStory/BibleStory/AVFoundationNarrationPlayer.swift \
  app/BibleStory/BibleStory/LibraryView.swift \
  app/BibleStory/BibleStory/StoryPlayerView.swift \
  app/BibleStory/BibleStory/ChildZoneView.swift \
  app/BibleStory/BibleStory.xcodeproj
git commit -m "feat(app): child-zone Library + Story Player wired over BibleStoryCore"
```

---

## Self-Review

**Spec coverage (against PRD §5.2, §6.1, §8, §11, Epic B):**
- B1 pick a story from a friendly library (§5.2 step 1) → `LibraryModel` (Task 6) + `LibraryView` tiles (Task 8). ✅
- B2 narrated story with pictures (§5.2 step 2, §6.1 FR-2) → `StoryPlayerModel` + `NarrationPlayer` (Tasks 3–5) + `StoryPlayerView` full-bleed illustration + `AVFoundationNarrationPlayer` (Task 8). ✅
- B3 pause/replay/continue (§5.2 step 2) → `play()`/`pause()`/`replayPage()`/`advance()`/`back()` (Tasks 4–5) + control bar (Task 8). ✅
- B4 progress cue / completed markers (§5.2 step 4) → `StoryProgressStore` + `LibraryModel.completedStoryIDs` (Task 6) + `UserDefaultsStoryProgressStore` + tile badge (Tasks 7–8). ✅
- Wonder pauses (§5.2 step 3) → `StoryPage.isWonderPause` + `StoryPlayerModel.atWonderPause` (Tasks 1, 4) + `WonderPauseCue` (Task 8). The ask-a-question loop itself is P4 — the cue is visual-only here, as scoped. ✅
- Completion/reward (§5.2 step 4) → `StoryPlayerModel.finished` (Task 4) + `CompletionRewardView` + `markCompleted` on finish (Task 8). ✅
- Content pipeline (§6.1 FR-1/FR-2, §11) → JSON schema + `StoryDecoder` (Task 2) + one real committed "David & Goliath" story with a wonder pause (Task 7) + `BundledStoryLibrary` (Task 7). Illustration + premium-TTS audio production is explicitly OUT of code scope (content-ops); only placeholder asset names ship. ✅
- Never-generate-Scripture invariant (§1.3, §7) → narration is fixed committed assets; no runtime text generation anywhere in P3. ✅

**Cross-plan contract:** every P3 type matches `2026-07-08-shared-interfaces.md` exactly — `StoryPage`, `Story` (fields + protocols), `StoryLibrary`, `NarrationPlayer`, `StoryProgressStore` (signatures), `StoryPlayerModel` (`currentPageIndex`, `isPlaying`, `advance()`/`back()`/`replayPage()`, `atWonderPause`, `finished`), `LibraryModel` (stories + completed markers). `StoryDecoder` is the plan's own testable addition. `AppModel`/`Zone`/`ParentGate` from P1 are consumed unchanged; the only P1 file modified is `ChildZoneView.swift` (additive — placeholder text swapped for `LibraryView`, gated parent button preserved). ✅

**Deviations / assumptions (flagged):**
- **Extended `StoryPlayerModel` with `play()` and `pause()`** beyond the shared contract's representative list, to satisfy PRD B3 pause/continue. Both use only the shared `NarrationPlayer` protocol methods; no new cross-plan seam. ✅
- **`StoryDecoder` uses a `{ schemaVersion, stories: [...] }` wrapper** returning `[Story]` (matches the contract's "decodes … into `[Story]`"); the one committed sample lives as a single-element `stories` array so the same schema scales to the ~12-story launch library.
- **`UserDefaultsStoryProgressStore` (device-local) is the concrete progress store for P3**; cross-device CloudKit sync is P6. A fixed `activeChildID` stands in for the real profile until P2 supplies `ChildProfile`. Both are noted inline.
- **`BundledStoryLibrary` "verifies asset names"** by decoding through the validating `StoryDecoder` (non-empty title/cover/image/audio names) and asserting on failure; verifying that the actual art/audio *files* exist is intentionally deferred to content-ops.
- **App target uses XcodeGen** (`project.yml` + `xcodegen generate`) per the shared-interfaces convention and the existing repo state (P1's app-shell commit is tagged `(xcodegen)`), rather than P1's prose "create in Xcode" step. Core-package test commands use the required `swift test --package-path …` absolute form.

**Placeholder scan:** no "TBD/TODO/handle appropriately" in code, tests, or commands; every code step shows complete code and every command has an exact expected output. Simulator name `iPhone 17` confirmed present in the environment. ✅

**Type/usage consistency:** `Story`/`StoryPage` fields, `NarrationPlayer.play(assetNamed:)`/`pause()`/`stop()`, `StoryLibrary.allStories()`/`story(id:)`, `StoryProgressStore.markCompleted(storyID:childID:)`/`completedStoryIDs(childID:)`, and the `StoryPlayerModel`/`LibraryModel` members are used identically across Tasks 1–8, the JSON schema, the test doubles, and the app glue. ✅
