# P7 — Safety & Crisis Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the danger/crisis pathway. When the ask-a-question loop (P4) returns a `QuestionResponse` with `isCrisis == true`, the app presents a gentle, calm, full-screen response that urges the child to tell a trusted grown-up — never counseling, never promising secrecy, never continuing to probe — fires a parent alert (local notification now / APNs-via-CloudKit path documented) plus creates a sanitized `CrisisEvent` the parent dashboard (P6) surfaces, then returns the child to a calm, neutral state.

**Architecture:** All decision logic lives in the platform-agnostic `BibleStoryCore` Swift package and is unit-tested from the command line with `swift test` — no simulator needed. The crisis flow is driven by an `@MainActor @Observable` `CrisisFlowModel` that depends only on a `CrisisAlertService` **protocol** (so the core stays testable with a mock); the concrete `APNsCrisisAlertService`, the SwiftUI crisis screen, and the wiring into P4's ask overlay live in the thin `BibleStory` app target and are verified by `xcodebuild` build + a manual checklist. Privacy is structural: `CrisisEvent.triggerSummary` is sanitized in the core so the child's raw words never persist, and the alert body carries no transcript.

**Tech Stack:** Swift 6, SwiftUI, Observation framework, UserNotifications (local notification + APNs registration), Swift Package Manager + XCTest, XcodeGen. No third-party dependencies.

## Global Constraints

_Every task's requirements implicitly include this section._

- **Prerequisites:** P1 (app foundation), P4 (ask-a-question loop — provides `QuestionResponse`, `ResponseClass`, `AskQuestionModel` in `BibleStoryCore`), and P6 (parent dashboard — consumes `CrisisEvent`) are complete. This plan uses their shared-contract types verbatim and does not redefine them.
- **Deployment target:** iOS 17.0 minimum (enables the `@Observable` macro).
- **Language/tools:** `swift-tools-version: 6.0`; Swift 6 language mode. Core logic in `app/BibleStoryCore`, Apple-framework glue in `app/BibleStory`. `project.yml` is the source of truth for the app target; regenerate with `xcodegen generate` from `app/BibleStory/`.
- **Class-5 safety invariant (behavior-spec §Class 5, PRD §5.4, D1):** the crisis flow MUST NOT counsel the child, MUST NOT promise or imply secrecy, MUST NOT keep probing, and MUST urge telling a trusted grown-up **and** alert the parent. This is encoded as a test (Task 5) that fails if any forbidden pattern ever appears in the surfaced text.
- **Fire toward safety:** the routing predicate triggers the crisis flow if the response is flagged crisis **or** classified `.danger` — a bug that sets one but not the other still opens the flow.
- **Privacy (PRD §10, D2):** `CrisisEvent.triggerSummary` is sanitized in the core — whitespace-collapsed, length-capped, never the full raw transcript. The wiring passes a fixed category reason (never the child's words); the core sanitizes defensively anyway. The push/notification body carries no transcript, only a neutral prompt to open the parent area.
- **Cross-plan types:** use ONLY the shared-contract types (`CrisisEvent`, `CrisisResource`, `CrisisAlertService`, `CrisisResources`, `CrisisFlowModel` from "P7"; `QuestionResponse`/`ResponseClass`/`AskQuestionModel` from "P4"; `ChildProfile` from "P2"). P7 adds only its own internal helpers (`CrisisEvent.sanitizedSummary`, `CrisisRouting`).
- **Human review (behavior-spec, PRD §5.4 step 4):** every danger-class model behavior is human-reviewed before ship. P7 is the *runtime* pathway; it does not relax that gate.

---

### Task 1: `CrisisEvent` value type + trigger sanitizer

**Files:**
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/CrisisEvent.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/CrisisEventTests.swift`

**Interfaces:**
- Consumes: `Foundation` (`UUID`, `Date`).
- Produces:
  - `public struct CrisisEvent: Identifiable, Sendable, Equatable, Codable` with `public let id: UUID`, `childID: UUID`, `createdAt: Date`, `triggerSummary: String`, and a `public init(...)`.
  - `public static let CrisisEvent.maxSummaryLength = 140`
  - `public static func CrisisEvent.sanitizedSummary(from reason: String) -> String` — collapses whitespace/newlines to single spaces, caps length (privacy: no full raw transcript), and returns a neutral default for empty input.

- [ ] **Step 1: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/CrisisEventTests.swift`:
```swift
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
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "CrisisEventTests"
```
Expected: BUILD FAILURE — `cannot find 'CrisisEvent' in scope`.

- [ ] **Step 3: Implement `CrisisEvent` + sanitizer**

Create `app/BibleStoryCore/Sources/BibleStoryCore/CrisisEvent.swift`:
```swift
import Foundation

/// A sanitized record that a danger/crisis input occurred. Written by the
/// crisis flow and surfaced by the parent dashboard (P6). Contains no raw
/// child transcript — only a bounded, whitespace-collapsed summary.
public struct CrisisEvent: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public let childID: UUID
    public let createdAt: Date
    /// Sanitized; never the raw transcript beyond the minimum. See `sanitizedSummary`.
    public let triggerSummary: String

    public init(id: UUID, childID: UUID, createdAt: Date, triggerSummary: String) {
        self.id = id
        self.childID = childID
        self.createdAt = createdAt
        self.triggerSummary = triggerSummary
    }
}

extension CrisisEvent {
    /// Maximum characters retained in a trigger summary (privacy: no full transcript).
    public static let maxSummaryLength = 140

    /// Reduces a raw reason to a bounded, single-line summary so the child's
    /// full words never persist. Empty/whitespace input yields a neutral default.
    public static func sanitizedSummary(from reason: String) -> String {
        let collapsed = reason
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")

        guard !collapsed.isEmpty else {
            return "Your child may need a caring grown-up's help."
        }
        guard collapsed.count > maxSummaryLength else { return collapsed }

        let cutoff = collapsed.index(collapsed.startIndex, offsetBy: maxSummaryLength)
        return String(collapsed[..<cutoff]) + "…"
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "CrisisEventTests"
```
Expected: PASS — `Test Suite 'CrisisEventTests' passed`.

- [ ] **Step 5: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): add sanitized CrisisEvent value type for the crisis flow"
```

---

### Task 2: `CrisisResource` + `CrisisResources.forLocale` (988 US default)

**Files:**
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/CrisisResource.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/CrisisResourcesTests.swift`

**Interfaces:**
- Consumes: `Foundation` (`Locale`).
- Produces:
  - `public struct CrisisResource: Sendable, Equatable` with `public let label: String`, `public let contact: String`, and a `public init(label:contact:)`.
  - `public enum CrisisResources { public static func forLocale(_ id: String) -> [CrisisResource] }` — a US resource table (988 Lifeline, Childhelp, 911) that all locales fall back to for the MVP (PRD Open Question Q5).

- [ ] **Step 1: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/CrisisResourcesTests.swift`:
```swift
import XCTest
@testable import BibleStoryCore

final class CrisisResourcesTests: XCTestCase {
    func testUSLocaleIncludes988() {
        let resources = CrisisResources.forLocale("en_US")
        XCTAssertFalse(resources.isEmpty)
        XCTAssertTrue(resources.contains { $0.contact == "988" })
    }

    func testUnknownLocaleFallsBackToUSDefault() {
        let resources = CrisisResources.forLocale("xx_ZZ")
        XCTAssertFalse(resources.isEmpty)
        XCTAssertTrue(resources.contains { $0.contact == "988" },
                      "988 is the MVP default per PRD Q5")
    }

    func testResourceStoresLabelAndContact() {
        let r = CrisisResource(label: "Emergency", contact: "911")
        XCTAssertEqual(r.label, "Emergency")
        XCTAssertEqual(r.contact, "911")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "CrisisResourcesTests"
```
Expected: BUILD FAILURE — `cannot find 'CrisisResources' in scope`.

- [ ] **Step 3: Implement `CrisisResource` + `CrisisResources`**

Create `app/BibleStoryCore/Sources/BibleStoryCore/CrisisResource.swift`:
```swift
import Foundation

/// A trusted place to get help, shown on the crisis screen and in the alert.
public struct CrisisResource: Sendable, Equatable {
    public let label: String
    public let contact: String

    public init(label: String, contact: String) {
        self.label = label
        self.contact = contact
    }
}

/// Locale → crisis resources. US 988 is the MVP default; other locales fall
/// back to it until localized tables land (PRD Open Question Q5).
public enum CrisisResources {
    public static func forLocale(_ id: String) -> [CrisisResource] {
        let region = Locale(identifier: id).region?.identifier
        switch region {
        case "US":
            return unitedStates
        default:
            return unitedStates
        }
    }

    static let unitedStates: [CrisisResource] = [
        CrisisResource(label: "988 Suicide & Crisis Lifeline (call or text)", contact: "988"),
        CrisisResource(label: "Childhelp National Child Abuse Hotline", contact: "1-800-422-4453"),
        CrisisResource(label: "Emergency", contact: "911"),
    ]
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "CrisisResourcesTests"
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): add CrisisResource + locale resource table (988 US default)"
```

---

### Task 3: `CrisisAlertService` + `CrisisFlowModel.present(...)` fires one sanitized alert

**Files:**
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/CrisisAlertService.swift`
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/CrisisFlowModel.swift`
- Modify: `app/BibleStoryCore/Tests/BibleStoryCoreTests/TestDoubles.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/CrisisFlowModelTests.swift`

**Interfaces:**
- Consumes: `CrisisEvent` (Task 1), `CrisisResource`/`CrisisResources` (Task 2).
- Produces:
  - `public protocol CrisisAlertService: Sendable { func notifyParent(_ event: CrisisEvent) async }`
  - `@MainActor @Observable public final class CrisisFlowModel` with `public init(alertService: CrisisAlertService, localeID: String = Locale.current.identifier)`, `public private(set) var event: CrisisEvent?`, `public private(set) var resources: [CrisisResource]`, `public let message: String`, `public var isPresenting: Bool`, and `public func present(childID: UUID, reason: String, createdAt: Date) async`.
  - Test double `MockCrisisAlertService` recording `notifiedEvents`.

- [ ] **Step 1: Add the alert-service test double**

Add to `app/BibleStoryCore/Tests/BibleStoryCoreTests/TestDoubles.swift`:
```swift
/// Records every event it is asked to deliver, so tests can assert exactly-once
/// alerting and sanitized payloads. `@MainActor` to match `CrisisFlowModel`.
@MainActor
final class MockCrisisAlertService: CrisisAlertService {
    private(set) var notifiedEvents: [CrisisEvent] = []

    nonisolated init() {}

    func notifyParent(_ event: CrisisEvent) async {
        notifiedEvents.append(event)
    }
}
```
Note: `CrisisAlertService.notifyParent` is `async`, so a `@MainActor` conformance is legal — this mirrors P1's `ControllableParentGate`.

- [ ] **Step 2: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/CrisisFlowModelTests.swift`:
```swift
import XCTest
@testable import BibleStoryCore

@MainActor
final class CrisisFlowModelTests: XCTestCase {
    func testPresentFiresExactlyOneSanitizedAlertAndPopulatesResources() async {
        let alerts = MockCrisisAlertService()
        let model = CrisisFlowModel(alertService: alerts, localeID: "en_US")
        let childID = UUID()
        let when = Date(timeIntervalSince1970: 1_700_000_000)

        await model.present(
            childID: childID,
            reason: "multi\nline   transcript-ish reason",
            createdAt: when
        )

        // Exactly one parent alert.
        XCTAssertEqual(alerts.notifiedEvents.count, 1)

        // Event is present, correctly attributed, and sanitized.
        let event = try! XCTUnwrap(model.event)
        XCTAssertEqual(event.childID, childID)
        XCTAssertEqual(event.createdAt, when)
        XCTAssertEqual(alerts.notifiedEvents.first, event)
        XCTAssertFalse(event.triggerSummary.contains("\n"), "summary is sanitized")
        XCTAssertEqual(event.triggerSummary, "multi line transcript-ish reason")

        // Resources populated for the locale.
        XCTAssertTrue(model.resources.contains { $0.contact == "988" })
        XCTAssertTrue(model.isPresenting)
    }
}
```

- [ ] **Step 3: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "CrisisFlowModelTests"
```
Expected: BUILD FAILURE — `cannot find type 'CrisisAlertService'` / `cannot find 'CrisisFlowModel' in scope`.

- [ ] **Step 4: Implement the protocol + model (present path)**

Create `app/BibleStoryCore/Sources/BibleStoryCore/CrisisAlertService.swift`:
```swift
/// Delivers a crisis alert to the parent (APNs / local notification in the app
/// target). The core depends only on this protocol so it stays testable.
public protocol CrisisAlertService: Sendable {
    func notifyParent(_ event: CrisisEvent) async
}
```

Create `app/BibleStoryCore/Sources/BibleStoryCore/CrisisFlowModel.swift`:
```swift
import Foundation
import Observation

/// Drives the danger/crisis screen. Builds a sanitized `CrisisEvent`, alerts the
/// parent exactly once, and exposes trusted resources plus a fixed gentle
/// message. It NEVER counsels, promises secrecy, or probes — it only urges the
/// child to tell a trusted grown-up. `createdAt` is passed in from the app layer
/// so the core stays deterministic.
@MainActor
@Observable
public final class CrisisFlowModel {
    /// The active crisis event while the screen is up; `nil` when calm.
    public private(set) var event: CrisisEvent?

    /// Trusted resources for the child's locale (988 in the US).
    public private(set) var resources: [CrisisResource] = []

    /// The fixed message shown to the child. See Task 5 for the safety invariant
    /// this string must satisfy: urges a trusted grown-up; no counseling,
    /// secrecy, or probing.
    public let message = "That sounds really important, and I'm so glad you told me. Please talk to a grown-up you trust — like a parent, a teacher, or someone who loves you. They can help you."

    /// True while the crisis screen should be shown.
    public var isPresenting: Bool { event != nil }

    private let alertService: CrisisAlertService
    private let localeID: String

    public init(alertService: CrisisAlertService,
                localeID: String = Locale.current.identifier) {
        self.alertService = alertService
        self.localeID = localeID
    }

    /// Opens the crisis flow: builds a sanitized event, shows resources, and
    /// alerts the parent exactly once. No-ops if a flow is already presenting.
    public func present(childID: UUID, reason: String, createdAt: Date) async {
        guard event == nil else { return }   // one flow / one alert at a time

        let newEvent = CrisisEvent(
            id: UUID(),
            childID: childID,
            createdAt: createdAt,
            triggerSummary: CrisisEvent.sanitizedSummary(from: reason)
        )
        event = newEvent
        resources = CrisisResources.forLocale(localeID)

        await alertService.notifyParent(newEvent)
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "CrisisFlowModelTests"
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): CrisisFlowModel.present fires one sanitized parent alert + resources"
```

---

### Task 4: `returnToCalm()` resets state + re-entrancy (no double alert)

**Files:**
- Modify: `app/BibleStoryCore/Sources/BibleStoryCore/CrisisFlowModel.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/CrisisFlowModelTests.swift`

**Interfaces:**
- Consumes: `CrisisFlowModel` (Task 3).
- Produces: `public func returnToCalm()` on `CrisisFlowModel` — clears `event` and `resources`, returning the child to a calm state. Also proves `present` is idempotent while presenting (fires at most one alert).

- [ ] **Step 1: Write the failing test**

Add to `CrisisFlowModelTests`:
```swift
    func testReentrantPresentFiresOnlyOneAlert() async {
        let alerts = MockCrisisAlertService()
        let model = CrisisFlowModel(alertService: alerts, localeID: "en_US")
        let childID = UUID()
        let when = Date(timeIntervalSince1970: 1_700_000_000)

        await model.present(childID: childID, reason: "a", createdAt: when)
        await model.present(childID: childID, reason: "b", createdAt: when) // ignored

        XCTAssertEqual(alerts.notifiedEvents.count, 1, "second present must be a no-op")
    }

    func testReturnToCalmResetsState() async {
        let alerts = MockCrisisAlertService()
        let model = CrisisFlowModel(alertService: alerts, localeID: "en_US")
        await model.present(childID: UUID(), reason: "x", createdAt: Date())
        XCTAssertTrue(model.isPresenting)          // precondition

        model.returnToCalm()

        XCTAssertNil(model.event)
        XCTAssertTrue(model.resources.isEmpty)
        XCTAssertFalse(model.isPresenting)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "CrisisFlowModelTests/testReturnToCalmResetsState"
```
Expected: BUILD FAILURE — `value of type 'CrisisFlowModel' has no member 'returnToCalm'`. (`testReentrantPresentFiresOnlyOneAlert` already passes from the Task 3 guard; this step drives the missing method.)

- [ ] **Step 3: Implement `returnToCalm()`**

Add to `CrisisFlowModel` (inside the class, after `present`):
```swift
    /// Dismisses the crisis screen and returns the child to a calm, neutral state.
    public func returnToCalm() {
        event = nil
        resources = []
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "CrisisFlowModelTests"
```
Expected: PASS — both new tests and the Task 3 test green.

- [ ] **Step 5: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): CrisisFlowModel.returnToCalm resets state; present stays idempotent"
```

---

### Task 5: Class-5 safety invariant — urges a grown-up, never counsels/secrets/probes

This is the falsifiable encoding of behavior-spec Class 5 (PRD §7, D1). It fails if any forbidden pattern ever appears in the surfaced text (the message or any resource label). No production code changes are expected — this locks the invariant so a future copy edit cannot silently break it.

**Files:**
- Modify (only if the test fails): `app/BibleStoryCore/Sources/BibleStoryCore/CrisisFlowModel.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/CrisisFlowModelTests.swift`

**Interfaces:**
- Consumes: `CrisisFlowModel` (Task 3), `CrisisResources` (Task 2).
- Produces: verified guarantee that the surfaced crisis text urges telling a trusted grown-up and contains none of the forbidden secrecy/counseling/probing patterns.

- [ ] **Step 1: Write the test**

Add to `CrisisFlowModelTests`:
```swift
    func testSurfacedTextUrgesGrownUpAndNeverCounselsOrKeepsSecrets() async {
        let model = CrisisFlowModel(alertService: MockCrisisAlertService(), localeID: "en_US")
        await model.present(childID: UUID(), reason: "x", createdAt: Date())

        // Everything the child could read on the screen.
        let surfaced = ([model.message] + model.resources.map(\.label))
            .joined(separator: " ")
            .lowercased()

        // MUST urge telling a trusted grown-up.
        XCTAssertTrue(model.message.lowercased().contains("grown-up"))
        XCTAssertTrue(model.message.lowercased().contains("trust"))

        // MUST NOT counsel, promise secrecy, or keep probing.
        let forbidden = [
            "secret", "don't tell", "dont tell", "between us", "just between",
            "keep it", "keep this", "you should", "here's what", "heres what",
            "my advice", "tell me more", "what happened", "?",
        ]
        for pattern in forbidden {
            XCTAssertFalse(surfaced.contains(pattern),
                           "crisis text must not contain forbidden pattern: \(pattern)")
        }
    }
```

- [ ] **Step 2: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "CrisisFlowModelTests/testSurfacedTextUrgesGrownUpAndNeverCounselsOrKeepsSecrets"
```
Expected: PASS immediately — the Task 3 `message` and Task 2 resource labels already satisfy the invariant. If it FAILS, the copy has drifted into counseling/secrecy/probing; fix `CrisisFlowModel.message` (and/or the resource labels) so it only urges telling a trusted grown-up, with no advice, no secrecy, and no follow-up questions (no `?`).

- [ ] **Step 3: Commit**

```bash
git add app/BibleStoryCore/Tests app/BibleStoryCore/Sources
git commit -m "test(app): lock class-5 invariant — crisis text urges a grown-up, never counsels/secrets/probes"
```

---

### Task 6: `CrisisRouting` predicate — map a `QuestionResponse` to triggering the flow

**Files:**
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/CrisisRouting.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/CrisisRoutingTests.swift`

**Interfaces:**
- Consumes: `QuestionResponse`, `ResponseClass` (P4 shared-contract types, already in `BibleStoryCore`).
- Produces: `public enum CrisisRouting { public static func shouldTriggerCrisisFlow(for response: QuestionResponse) -> Bool }` — returns `true` if the response is flagged `isCrisis` **or** classified `.danger` (fire toward safety).

- [ ] **Step 1: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/CrisisRoutingTests.swift`:
```swift
import XCTest
@testable import BibleStoryCore

final class CrisisRoutingTests: XCTestCase {
    private func response(isCrisis: Bool, cls: ResponseClass) -> QuestionResponse {
        QuestionResponse(
            spokenText: "…",
            responseClass: cls,
            retrievedVerse: nil,
            logToConversationGuide: false,
            isCrisis: isCrisis
        )
    }

    func testCrisisFlagTriggers() {
        XCTAssertTrue(CrisisRouting.shouldTriggerCrisisFlow(
            for: response(isCrisis: true, cls: .safeSharedCore)))
    }

    func testDangerClassTriggersEvenWithoutFlag() {
        // Belt-and-suspenders: a danger classification alone still opens the flow.
        XCTAssertTrue(CrisisRouting.shouldTriggerCrisisFlow(
            for: response(isCrisis: false, cls: .danger)))
    }

    func testNonCrisisDoesNotTrigger() {
        XCTAssertFalse(CrisisRouting.shouldTriggerCrisisFlow(
            for: response(isCrisis: false, cls: .safeSharedCore)))
        XCTAssertFalse(CrisisRouting.shouldTriggerCrisisFlow(
            for: response(isCrisis: false, cls: .redLine)))
    }
}
```
Note: `QuestionResponse(spokenText:responseClass:retrievedVerse:logToConversationGuide:isCrisis:)` is P4's public memberwise init. If P4 named its init differently, adapt the call; the field names are fixed by the shared contract.

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "CrisisRoutingTests"
```
Expected: BUILD FAILURE — `cannot find 'CrisisRouting' in scope`.

- [ ] **Step 3: Implement `CrisisRouting`**

Create `app/BibleStoryCore/Sources/BibleStoryCore/CrisisRouting.swift`:
```swift
/// Decides whether a responder's answer must open the crisis flow (P7) instead
/// of being spoken as a normal reply. Fires toward safety: either the explicit
/// `isCrisis` flag or a `.danger` classification triggers it.
public enum CrisisRouting {
    public static func shouldTriggerCrisisFlow(for response: QuestionResponse) -> Bool {
        response.isCrisis || response.responseClass == .danger
    }
}
```

- [ ] **Step 4: Run the full core suite to verify everything passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore
```
Expected: PASS — all P1, P4, P6, and new P7 core tests green.

- [ ] **Step 5: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): CrisisRouting predicate maps isCrisis/danger to the crisis flow"
```

---

### Task 7: App — `APNsCrisisAlertService` + notification registration + push capability

Adds the concrete `CrisisAlertService`. Verified by build + manual run, not `swift test`.

**MVP delivery decision:** The alert is delivered as an immediate **local** notification via `UNUserNotificationCenter`. In the common single-device family setup (the phone is handed from child to parent — PRD §5.1 hand-off), this reaches the parent without any server, and the event is also persisted to CloudKit (P6) and surfaced in the dashboard. Remote delivery to a *separate* parent device is a documented post-MVP path: the parent device holds a CloudKit subscription on the private `CrisisEvent` record; saving the event triggers an APNs push from CloudKit — no bespoke APNs server (privacy is the product, PRD §9.2). `registerForRemoteNotifications()` + the push entitlement are wired now so that path needs no client rework.

**Files:**
- Create: `app/BibleStory/BibleStory/APNsCrisisAlertService.swift`
- Modify: `app/BibleStory/BibleStory/BibleStoryApp.swift` (additive — add an `AppDelegate` that requests notification authorization and registers for remote notifications)
- Modify: `app/BibleStory/project.yml` (add the Push Notifications entitlement)
- Generated by xcodegen: `app/BibleStory/BibleStory/BibleStory.entitlements`

**Interfaces:**
- Consumes: `CrisisAlertService`, `CrisisEvent` (from `BibleStoryCore`).
- Produces: `final class APNsCrisisAlertService: CrisisAlertService` and app-launch notification registration.

- [ ] **Step 1: Write the concrete alert service**

Create `app/BibleStory/BibleStory/APNsCrisisAlertService.swift`:
```swift
import Foundation
import UserNotifications
import BibleStoryCore

/// Delivers a crisis alert to the parent.
///
/// MVP: an immediate *local* notification (works on the shared family device
/// with no server). The `CrisisEvent` is also persisted to CloudKit (P6) and
/// shown in the parent dashboard. Post-MVP remote delivery to another device
/// rides a CloudKit private-DB subscription → APNs push (no custom server).
///
/// The notification body carries NO transcript — only a neutral prompt to open
/// the parent area — so nothing sensitive appears on the lock screen.
final class APNsCrisisAlertService: CrisisAlertService {
    func notifyParent(_ event: CrisisEvent) async {
        let content = UNMutableNotificationContent()
        content.title = "Your child may need you"
        content.body = "A moment during story time may need a caring grown-up. Open the parent area for guidance and resources."
        content.sound = .default
        content.userInfo = [
            "crisisEventID": event.id.uuidString,
            "childID": event.childID.uuidString,
        ]

        let request = UNNotificationRequest(
            identifier: event.id.uuidString,
            content: content,
            trigger: nil   // deliver immediately
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
```

- [ ] **Step 2: Add notification registration to the app entry point (additive to P1)**

Replace `app/BibleStory/BibleStory/BibleStoryApp.swift`:
```swift
import SwiftUI
import UIKit
import UserNotifications
import BibleStoryCore

@main
struct BibleStoryApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appModel = AppModel(gate: BiometricParentGate())

    var body: some Scene {
        WindowGroup {
            RootView(appModel: appModel)
        }
    }
}

/// Requests notification permission and registers for remote notifications so
/// crisis alerts (P7) can reach the parent. The remote token is used only by the
/// documented CloudKit/APNs path; the MVP delivers local notifications.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Task {
            let center = UNUserNotificationCenter.current()
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run { application.registerForRemoteNotifications() }
        }
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // APNs token for the post-MVP CloudKit/server path. Not uploaded in MVP.
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Non-fatal: local-notification delivery still works.
    }
}
```

- [ ] **Step 3: Add the Push Notifications entitlement to `project.yml`**

Edit `app/BibleStory/project.yml` — add an `entitlements:` block to the `BibleStory` target (leave everything else, including the `GENERATE_INFOPLIST_FILE` settings, unchanged):
```yaml
targets:
  BibleStory:
    type: application
    platform: iOS
    sources:
      - path: BibleStory
    entitlements:
      path: BibleStory/BibleStory.entitlements
      properties:
        aps-environment: development
    dependencies:
      - package: BibleStoryCore
        product: BibleStoryCore
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.biblestory.app
        MARKETING_VERSION: "1.0"
        CURRENT_PROJECT_VERSION: "1"
        SWIFT_VERSION: "6.0"
        TARGETED_DEVICE_FAMILY: "1,2"
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_NSFaceIDUsageDescription: "Confirm you're a grown-up to open the parent area."
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
```
xcodegen writes `BibleStory/BibleStory.entitlements` with the `aps-environment` key and sets `CODE_SIGN_ENTITLEMENTS`. This is the "Push Notifications" capability. (Simulator builds do not validate this against a provisioning profile.)

- [ ] **Step 4: Regenerate the Xcode project**

Run (from `app/BibleStory/`):
```bash
xcodegen generate
```
Expected: `Created project at .../app/BibleStory/BibleStory.xcodeproj`. Confirm `app/BibleStory/BibleStory/BibleStory.entitlements` now exists and contains `aps-environment`.

- [ ] **Step 5: Build for the Simulator**

Run (from `app/BibleStory/`):
```bash
xcodebuild -project BibleStory.xcodeproj -scheme BibleStory \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: `** BUILD SUCCEEDED **`. (If code signing complains about the entitlement, append `CODE_SIGNING_ALLOWED=NO` — simulator builds don't need a push profile. If the simulator name differs, list with `xcrun simctl list devices` and substitute.)

- [ ] **Step 6: Manual run verification**

Run the app in the Simulator and verify:
1. On first launch, iOS shows the **notification permission** prompt → tap **Allow**.
2. The app does not crash if permission is denied (local-notification delivery is still attempted; no crash).
3. `BibleStory.entitlements` is present in the project navigator with the Push Notifications capability.

- [ ] **Step 7: Commit**

```bash
git add app/BibleStory
git commit -m "feat(app): APNsCrisisAlertService + notification registration + push capability"
```

---

### Task 8: App — `CrisisView` (calm, warm, full-screen crisis screen)

**Files:**
- Create: `app/BibleStory/BibleStory/CrisisView.swift`

**Interfaces:**
- Consumes: `CrisisFlowModel`, `CrisisResource` (from `BibleStoryCore`).
- Produces: `struct CrisisView: View` — shows `model.message` large and warm, lists `model.resources`, and a single "Okay" button that calls `model.returnToCalm()`.

- [ ] **Step 1: Write the crisis screen**

Create `app/BibleStory/BibleStory/CrisisView.swift`:
```swift
import SwiftUI
import BibleStoryCore

/// Calm, warm, full-screen crisis response (PRD §5.4). Shows the gentle message
/// and trusted resources; a single "Okay" returns the child to a calm state.
/// It never counsels, never probes, never implies secrecy.
struct CrisisView: View {
    let model: CrisisFlowModel

    var body: some View {
        ZStack {
            Color(.systemIndigo).opacity(0.10).ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.pink.opacity(0.85))
                    .accessibilityHidden(true)

                Text(model.message)
                    .font(.title2.weight(.medium))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)

                if !model.resources.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(model.resources, id: \.contact) { resource in
                            VStack(spacing: 2) {
                                Text(resource.label)
                                    .font(.callout.weight(.semibold))
                                    .multilineTextAlignment(.center)
                                Text(resource.contact)
                                    .font(.title3.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.top, 8)
                }

                Spacer()

                Button {
                    model.returnToCalm()
                } label: {
                    Text("Okay")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
                .accessibilityLabel("Okay")
            }
        }
    }
}

#Preview {
    let model = CrisisFlowModel(alertService: PreviewCrisisAlertService(), localeID: "en_US")
    return CrisisView(model: model)
        .task { await model.present(childID: UUID(), reason: "preview", createdAt: Date()) }
}

/// Preview-only no-op alert service.
private struct PreviewCrisisAlertService: CrisisAlertService {
    func notifyParent(_ event: CrisisEvent) async {}
}
```

- [ ] **Step 2: Regenerate + build**

Run (from `app/BibleStory/`):
```bash
xcodegen generate
xcodebuild -project BibleStory.xcodeproj -scheme BibleStory \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Manual run verification (via the SwiftUI preview)**

Open `CrisisView.swift` in Xcode and run the Preview (or temporarily point `RootView` at `CrisisView` for a manual check). Verify the checklist:
1. The screen is calm and full-bleed: soft background, large warm heart glyph, the gentle message centered and legible.
2. The message urges telling a trusted grown-up; there is **no** advice, no follow-up question, no "keep it secret."
3. The resources (988 Lifeline, Childhelp, Emergency) are listed with contacts.
4. A single large **Okay** button is present; tapping it calls `returnToCalm()` (in the preview, the message/resources clear).

- [ ] **Step 4: Commit**

```bash
git add app/BibleStory
git commit -m "feat(app): CrisisView — calm full-screen crisis response screen"
```

---

### Task 9: App — wire the crisis flow into P4's ask-a-question overlay (additive)

Hooks the crisis flow into the ask loop: when the responder returns `isCrisis` (or `.danger`), the overlay presents `CrisisView` full-screen instead of a normal reply, fires the parent alert, and — on "Okay" — returns to calm. This is an **additive** edit to P4's ask overlay view; only the new code is shown.

**Files:**
- Modify (additive, P4): `app/BibleStory/BibleStory/AskQuestionView.swift` — P4's SwiftUI overlay that renders `AskQuestionModel`. (If P4 named this view differently, apply the same additions to the view that presents the responder's `QuestionResponse`.)

**Interfaces:**
- Consumes: `AskQuestionModel` (exposes the current `QuestionResponse?` as `response`), `CrisisRouting`, `CrisisFlowModel`, `ChildProfile.id` (the active child).
- Produces: an ask overlay that branches to `CrisisView` on a crisis response and never speaks a normal reply for it.

- [ ] **Step 1: Give the overlay a `CrisisFlowModel` and the active child ID (additive)**

Add these stored properties to the `AskQuestionView` (alongside its existing `askModel`):
```swift
    // P7 — crisis flow, injected from the child zone / story player.
    let crisisFlow: CrisisFlowModel
    let childID: UUID           // the active ChildProfile's id (P2)
```

- [ ] **Step 2: Add the crisis branch to the overlay body (additive)**

Attach these modifiers to the overlay's root view (the same view that currently renders the response bubble). They present `CrisisView` full-screen when the flow is active, and trigger the flow when a crisis response arrives:
```swift
        // P7 — show the calm crisis screen full-screen instead of a normal reply.
        .fullScreenCover(isPresented: Binding(
            get: { crisisFlow.isPresenting },
            set: { presenting in if !presenting { crisisFlow.returnToCalm() } }
        )) {
            CrisisView(model: crisisFlow)
        }
        // P7 — when the responder flags danger, open the crisis flow (and do not
        // speak the reply). A fixed category reason is passed — never the child's
        // words; the core sanitizes defensively regardless.
        .onChange(of: askModel.response) { _, response in
            guard let response,
                  CrisisRouting.shouldTriggerCrisisFlow(for: response) else { return }
            Task {
                await crisisFlow.present(
                    childID: childID,
                    reason: "danger/crisis input during story time",
                    createdAt: Date()
                )
            }
        }
```
Note: `AskQuestionModel` exposes the current `QuestionResponse?` (shared contract). If P4's property is not literally named `response`, substitute P4's name. When `isCrisis`/`.danger` is detected, the overlay must NOT also invoke `ReplyVoicer.speak(...)` for that response — guard P4's speak call with `!CrisisRouting.shouldTriggerCrisisFlow(for: response)` if it isn't already gated by presentation state.

- [ ] **Step 3: Create + inject the `CrisisFlowModel` at the overlay's call site (additive)**

At the point where `AskQuestionView` is instantiated (P3/P4's story player / child zone), create the flow with the concrete alert service and pass the active child's id:
```swift
        AskQuestionView(
            askModel: askModel,
            crisisFlow: CrisisFlowModel(alertService: APNsCrisisAlertService()),
            childID: activeChild.id            // ChildProfile.id (P2)
        )
```
If the call site constructs `AskQuestionView` in more than one place, add the two new arguments in each. Prefer holding a single `@State private var crisisFlow = CrisisFlowModel(alertService: APNsCrisisAlertService())` on the presenting view so one flow instance is reused.

- [ ] **Step 4: Regenerate + build**

Run (from `app/BibleStory/`):
```bash
xcodegen generate
xcodebuild -project BibleStory.xcodeproj -scheme BibleStory \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 5: Manual run verification**

Run the app, open a story to a wonder-pause, and use the ask loop with P4's crisis-triggering stub (or a `QuestionResponder` mock that returns `isCrisis: true`). Verify the checklist:
1. On a crisis response, the **CrisisView** appears full-screen — the normal reply bubble is **not** shown and no reply is spoken.
2. A **notification** is delivered (the parent alert), and a `CrisisEvent` is created (observable via the dashboard once P6 sync is wired).
3. The crisis screen shows the gentle message + resources; tapping **Okay** dismisses it and returns to a calm, neutral state (not mid-story pressure).
4. A normal (non-crisis) response still renders/speaks as usual — the branch does not affect classes 1–4/6.

- [ ] **Step 6: Commit**

```bash
git add app/BibleStory
git commit -m "feat(app): wire crisis flow into the ask-a-question overlay (P4)"
```

---

## Self-Review

**Spec coverage (against PRD §4 Epic D, §5.4, §7 class 5, §10; behavior-spec Class 5):**
- D1 — scary input gently urged to tell a trusted grown-up, never counseled/secreted → `CrisisFlowModel.message` + Task 5 invariant test. ✅
- D2 — parent alerted immediately + given resources → `CrisisAlertService`/`APNsCrisisAlertService` (Tasks 3, 7) + `CrisisResources` (Task 2); Task 3 asserts exactly one alert. ✅
- PRD §5.4 flow: gentle full-screen response → `CrisisView` (Task 8); parent alert + dashboard entry → `CrisisEvent` (Task 1) fired to `CrisisAlertService` (Task 3), surfaced by P6; return to calm → `returnToCalm()` (Task 4) + "Okay" button (Task 8). ✅
- Behavior-spec Class 5 forbidden behaviors (counsel / secrecy / probing) → Task 5 forbidden-pattern test over message + resource labels; "urge a trusted grown-up" asserted positively. ✅
- Routing from the ask loop (`isCrisis`) → `CrisisRouting` (Task 6) + wiring (Task 9); fires toward safety on `.danger` too. ✅
- Human-review gate (PRD §5.4 step 4) → noted in Global Constraints; P7 is the runtime pathway, not a relaxation. ✅

**Privacy (PRD §10, D2):** `CrisisEvent.triggerSummary` sanitized in-core (Task 1) — whitespace-collapsed, capped at 140 chars, neutral default; the wiring passes a fixed category reason (never the transcript, Task 9); the notification body carries no transcript (Task 7). ✅

**Shared-contract fidelity:** `CrisisEvent`, `CrisisResource`, `CrisisAlertService`, `CrisisResources`, `CrisisFlowModel` match the "P7" contract exactly; `QuestionResponse`/`ResponseClass`/`AskQuestionModel` (P4) and `ChildProfile` (P2) are consumed, not redefined; `CrisisFlowModel.present(childID:reason:createdAt:)` uses the prompt-specified signature (createdAt injected from the app layer, consistent with the contract's determinism note). Internal-only additions: `CrisisEvent.sanitizedSummary`, `CrisisRouting`. ✅

**Layering:** all decision logic (`CrisisEvent`, sanitizer, `CrisisResources`, `CrisisFlowModel`, `CrisisRouting`) is in `BibleStoryCore` and TDD'd via `swift test`; Apple-framework glue (`APNsCrisisAlertService`, `UNUserNotificationCenter` registration, `CrisisView`, the P4 wiring) is in the app target and verified by build + manual checklist. ✅

**Additive-only edits to P1/P4:** `BibleStoryApp.swift` (P1) gains an `AppDelegate` adaptor for notification registration — no existing behavior removed; `AskQuestionView.swift` (P4) gains a crisis branch — no existing behavior removed. Both shown as complete new code. ✅

**Placeholder scan:** every code and test step shows complete code and an exact command with expected output; no "TBD/TODO/handle appropriately." The only adaptation notes concern P4's property/view names, which are fixed by the shared contract where it specifies them. ✅

**Type consistency:** `CrisisEvent(id:childID:createdAt:triggerSummary:)`, `CrisisResource(label:contact:)`, `CrisisResources.forLocale(_:)`, `CrisisAlertService.notifyParent(_:)`, `CrisisFlowModel(alertService:localeID:)` / `.present(childID:reason:createdAt:)` / `.returnToCalm()` / `.message` / `.resources` / `.event` / `.isPresenting`, and `CrisisRouting.shouldTriggerCrisisFlow(for:)` are used identically across Tasks 1–9 and the test doubles. ✅
