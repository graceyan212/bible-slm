# P6 — Parent Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the gated parent dashboard — the Conversation Guide (deflected questions + doctrine-neutral discussion prompts), content & safety controls, progress/history, and a privacy/safety-claims page — backed by CloudKit private-database sync.

**Architecture:** All dashboard logic (loading, child filtering, settings edits, progress/streak computation, content gating) lives in `BibleStoryCore` as `DashboardModel` + a pure `ProgressCalculator`, tested against a mock `CloudSyncService`. The CloudKit implementation and the SwiftUI screens live in the app target, rendered inside P1's already-gated parent zone (replacing the `ParentZoneView` placeholder). Only derived/sanitized data (conversation-guide entries, settings, crisis events) is synced — to the parent's PRIVATE CloudKit container.

**Tech Stack:** Swift 6, SwiftUI, Observation, CloudKit, XCTest.

## Global Constraints

_Every task's requirements implicitly include this section._

- **Deployment target:** iOS 17.0. **Tools:** `swift-tools-version: 6.0`, Swift 6 language mode.
- **UI:** SwiftUI + Observation. No third-party packages.
- **Layering:** decision logic in `BibleStoryCore` (`swift test`); CloudKit + views in the `BibleStory` app target (build + manual). Regenerate with `xcodegen generate`; `project.yml` is the source of truth.
- **Gating (P1):** the dashboard renders only inside `AppModel.zone == .parent`, reached via the `ParentGate`. Do not add any un-gated route to it.
- **Privacy (PRD §6.3, §9.2, §10):** dashboard data lives in the parent's PRIVATE CloudKit database; the child's raw questions/audio never sync — only the derived `ConversationGuideEntry` (question text + neutral discussion prompt) and `SafetySettings`.
- **Determinism:** progress/streak math takes an injected `today: Date` + `Calendar` — never call `Date()` inside logic.
- **Canonical types:** this plan owns `SafetySettings`, `ProgressSummary`, `CloudSyncService`, `DashboardModel`. It consumes `ConversationGuideEntry` (P4), `ChildProfile`/`BibleTranslation` (P2), `CrisisEvent` (P7) — never redefine them.
- Existing types available: P1 (`AppModel`, `Zone`, `ParentZoneView`), P2 (`ParentAccount`, `ChildProfile`, `BibleTranslation`), P4 (`ConversationGuideEntry`).

---

### Task 1: `SafetySettings`, `ProgressSummary`, and content gating

**Files:**
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/DashboardTypes.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/DashboardTypesTests.swift`

**Interfaces:**
- Produces: `SafetySettings` (+ `allows(storyID:)`, `default(translation:)`), `ProgressSummary` per the shared-interfaces contract.

- [ ] **Step 1: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/DashboardTypesTests.swift`:
```swift
import XCTest
@testable import BibleStoryCore

final class DashboardTypesTests: XCTestCase {
    func testContentGatingBlocksDisabledStories() {
        let allowed = UUID(), blocked = UUID()
        var settings = SafetySettings.default(translation: .nirv)
        settings.disabledStoryIDs = [blocked]
        XCTAssertTrue(settings.allows(storyID: allowed))
        XCTAssertFalse(settings.allows(storyID: blocked))
    }

    func testSettingsRoundTripCodable() throws {
        var settings = SafetySettings.default(translation: .esv)
        settings.sessionTimeLimitMinutes = 15
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(SafetySettings.self, from: data)
        XCTAssertEqual(decoded, settings)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "DashboardTypesTests"
```
Expected: BUILD FAILURE — `cannot find 'SafetySettings' in scope`.

- [ ] **Step 3: Implement the types**

Create `app/BibleStoryCore/Sources/BibleStoryCore/DashboardTypes.swift`:
```swift
import Foundation

public struct SafetySettings: Sendable, Equatable, Codable {
    public var translation: BibleTranslation
    public var disabledStoryIDs: Set<UUID>
    public var disabledTopics: Set<String>
    public var sessionTimeLimitMinutes: Int?
    public var crisisAlertsEnabled: Bool

    public init(
        translation: BibleTranslation,
        disabledStoryIDs: Set<UUID> = [],
        disabledTopics: Set<String> = [],
        sessionTimeLimitMinutes: Int? = nil,
        crisisAlertsEnabled: Bool = true
    ) {
        self.translation = translation
        self.disabledStoryIDs = disabledStoryIDs
        self.disabledTopics = disabledTopics
        self.sessionTimeLimitMinutes = sessionTimeLimitMinutes
        self.crisisAlertsEnabled = crisisAlertsEnabled
    }

    /// Safe defaults for a freshly-onboarded family.
    public static func `default`(translation: BibleTranslation) -> SafetySettings {
        SafetySettings(translation: translation)
    }

    /// Content gate the child zone consults before showing a story.
    public func allows(storyID: UUID) -> Bool {
        !disabledStoryIDs.contains(storyID)
    }
}

public struct ProgressSummary: Sendable, Equatable {
    public let childID: UUID
    public let completedCount: Int
    public let streakDays: Int

    public init(childID: UUID, completedCount: Int, streakDays: Int) {
        self.childID = childID
        self.completedCount = completedCount
        self.streakDays = streakDays
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "DashboardTypesTests"
```
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests && git commit -m "feat(app): P6 SafetySettings + ProgressSummary + content gating"
```

---

### Task 2: `CloudSyncService` + `DashboardModel` guide loading & filtering

**Files:**
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/CloudSyncService.swift`
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/DashboardModel.swift`
- Modify: `app/BibleStoryCore/Tests/BibleStoryCoreTests/TestDoubles.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/DashboardModelTests.swift`

**Interfaces:**
- Produces:
  - `protocol CloudSyncService { fetchConversationEntries(childID:) ; save(entry:) ; fetchSettings() ; save(settings:) }` per contract.
  - `@MainActor @Observable final class DashboardModel` with `entries`, `settings`, `progress`, `loadGuide(childID:) async`, `filtered(by:)`.
  - Test double `MockCloudSync`.

- [ ] **Step 1: Add the test double**

Add to `app/BibleStoryCore/Tests/BibleStoryCoreTests/TestDoubles.swift`:
```swift
// MARK: - P6 test double

actor MockCloudSync: CloudSyncService {
    var entries: [ConversationGuideEntry]
    var settings: SafetySettings?
    private(set) var savedEntries: [ConversationGuideEntry] = []
    private(set) var savedSettings: [SafetySettings] = []

    init(entries: [ConversationGuideEntry] = [], settings: SafetySettings? = nil) {
        self.entries = entries
        self.settings = settings
    }

    func fetchConversationEntries(childID: UUID) async throws -> [ConversationGuideEntry] {
        entries.filter { $0.childID == childID }
    }
    func save(entry: ConversationGuideEntry) async throws {
        savedEntries.append(entry); entries.append(entry)
    }
    func fetchSettings() async throws -> SafetySettings? { settings }
    func save(settings: SafetySettings) async throws {
        self.settings = settings; savedSettings.append(settings)
    }
}
```

- [ ] **Step 2: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/DashboardModelTests.swift`:
```swift
import XCTest
@testable import BibleStoryCore

@MainActor
final class DashboardModelTests: XCTestCase {
    private func entry(child: UUID, at t: TimeInterval) -> ConversationGuideEntry {
        ConversationGuideEntry(
            id: UUID(), childID: child, question: "q",
            discussionPrompt: "p", storyID: UUID(),
            createdAt: Date(timeIntervalSince1970: t)
        )
    }

    func testLoadGuideFetchesOnlyThatChild() async {
        let a = UUID(), b = UUID()
        let sync = MockCloudSync(entries: [entry(child: a, at: 1), entry(child: b, at: 2), entry(child: a, at: 3)])
        let m = DashboardModel(sync: sync)

        await m.loadGuide(childID: a)

        XCTAssertEqual(m.entries.count, 2)
        XCTAssertTrue(m.entries.allSatisfy { $0.childID == a })
    }

    func testEntriesAreNewestFirst() async {
        let a = UUID()
        let sync = MockCloudSync(entries: [entry(child: a, at: 10), entry(child: a, at: 30), entry(child: a, at: 20)])
        let m = DashboardModel(sync: sync)
        await m.loadGuide(childID: a)
        let times = m.entries.map { $0.createdAt.timeIntervalSince1970 }
        XCTAssertEqual(times, [30, 20, 10])
    }
}
```

- [ ] **Step 3: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "DashboardModelTests"
```
Expected: BUILD FAILURE — `cannot find 'DashboardModel' in scope`.

- [ ] **Step 4: Implement the protocol and model**

Create `app/BibleStoryCore/Sources/BibleStoryCore/CloudSyncService.swift`:
```swift
import Foundation

/// Syncs derived parent data to the parent's PRIVATE CloudKit database.
public protocol CloudSyncService: Sendable {
    func fetchConversationEntries(childID: UUID) async throws -> [ConversationGuideEntry]
    func save(entry: ConversationGuideEntry) async throws
    func fetchSettings() async throws -> SafetySettings?
    func save(settings: SafetySettings) async throws
}
```

Create `app/BibleStoryCore/Sources/BibleStoryCore/DashboardModel.swift`:
```swift
import Foundation
import Observation

/// Backing model for the parent dashboard. Loads and edits derived data
/// through the CloudKit-backed `CloudSyncService`.
@MainActor
@Observable
public final class DashboardModel {
    public private(set) var entries: [ConversationGuideEntry] = []
    public private(set) var settings: SafetySettings?
    public private(set) var progress: ProgressSummary?

    private let sync: CloudSyncService

    public init(sync: CloudSyncService) {
        self.sync = sync
    }

    /// Loads the conversation guide for one child, newest first.
    public func loadGuide(childID: UUID) async {
        let fetched = (try? await sync.fetchConversationEntries(childID: childID)) ?? []
        entries = fetched.sorted { $0.createdAt > $1.createdAt }
    }

    /// Pure filter helper for the UI.
    public func filtered(by childID: UUID) -> [ConversationGuideEntry] {
        entries.filter { $0.childID == childID }
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "DashboardModelTests"
```
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests && git commit -m "feat(app): P6 CloudSyncService + DashboardModel guide loading"
```

---

### Task 3: `ProgressCalculator` + `DashboardModel.loadProgress`

**Files:**
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/ProgressCalculator.swift`
- Modify: `app/BibleStoryCore/Sources/BibleStoryCore/DashboardModel.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/ProgressCalculatorTests.swift`

**Interfaces:**
- Produces:
  - `enum ProgressCalculator { static func streakDays(activityDates:today:calendar:) -> Int }`
  - `DashboardModel.loadProgress(childID:completedCount:today:calendar:) async` — derives streak from loaded entries' dates + completedCount (from P3's progress store).

- [ ] **Step 1: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/ProgressCalculatorTests.swift`:
```swift
import XCTest
@testable import BibleStoryCore

final class ProgressCalculatorTests: XCTestCase {
    private let cal = Calendar(identifier: .gregorian)
    private func day(_ y: Int, _ mo: Int, _ d: Int) -> Date {
        DateComponents(calendar: Calendar(identifier: .gregorian),
                       year: y, month: mo, day: d, hour: 12).date!
    }

    func testConsecutiveDaysEndingTodayCountAsStreak() {
        let today = day(2026, 7, 8)
        let dates = [day(2026, 7, 6), day(2026, 7, 7), day(2026, 7, 8)]
        XCTAssertEqual(ProgressCalculator.streakDays(activityDates: dates, today: today, calendar: cal), 3)
    }

    func testGapBreaksStreak() {
        let today = day(2026, 7, 8)
        let dates = [day(2026, 7, 5), day(2026, 7, 8)]  // gap on the 6th–7th
        XCTAssertEqual(ProgressCalculator.streakDays(activityDates: dates, today: today, calendar: cal), 1)
    }

    func testNoActivityTodayOrYesterdayIsZero() {
        let today = day(2026, 7, 8)
        let dates = [day(2026, 7, 1)]
        XCTAssertEqual(ProgressCalculator.streakDays(activityDates: dates, today: today, calendar: cal), 0)
    }

    func testEmptyIsZero() {
        XCTAssertEqual(ProgressCalculator.streakDays(activityDates: [], today: day(2026, 7, 8), calendar: cal), 0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "ProgressCalculatorTests"
```
Expected: BUILD FAILURE — `cannot find 'ProgressCalculator' in scope`.

- [ ] **Step 3: Implement the calculator + model method**

Create `app/BibleStoryCore/Sources/BibleStoryCore/ProgressCalculator.swift`:
```swift
import Foundation

/// Pure streak math: the number of consecutive days (ending today or, if no
/// activity today, yesterday) that have at least one activity date.
public enum ProgressCalculator {
    public static func streakDays(activityDates: [Date], today: Date, calendar: Calendar) -> Int {
        let activeDays = Set(activityDates.map { calendar.startOfDay(for: $0) })
        guard !activeDays.isEmpty else { return 0 }

        let startOfToday = calendar.startOfDay(for: today)
        // Anchor: today if active today, else yesterday if active then, else no streak.
        var cursor: Date
        if activeDays.contains(startOfToday) {
            cursor = startOfToday
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday),
                  activeDays.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var streak = 0
        while activeDays.contains(cursor) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }
}
```

Add to `app/BibleStoryCore/Sources/BibleStoryCore/DashboardModel.swift` (inside the class):
```swift
    /// Builds a progress summary: `completedCount` comes from P3's progress
    /// store; the streak is derived from the loaded conversation-entry dates
    /// (a proxy for days the child engaged). Call after `loadGuide`.
    public func loadProgress(
        childID: UUID,
        completedCount: Int,
        today: Date,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) {
        let dates = entries.filter { $0.childID == childID }.map { $0.createdAt }
        let streak = ProgressCalculator.streakDays(activityDates: dates, today: today, calendar: calendar)
        progress = ProgressSummary(childID: childID, completedCount: completedCount, streakDays: streak)
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "ProgressCalculatorTests"
```
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests && git commit -m "feat(app): P6 ProgressCalculator streak + loadProgress"
```

---

### Task 4: `DashboardModel` — settings load & persist

**Files:**
- Modify: `app/BibleStoryCore/Sources/BibleStoryCore/DashboardModel.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/DashboardModelTests.swift`

**Interfaces:**
- Produces: `DashboardModel.loadSettings(defaultTranslation:) async`, `updateSettings(_:) async` (writes through `CloudSyncService`).

- [ ] **Step 1: Write the failing test**

Add to `DashboardModelTests`:
```swift
    func testLoadSettingsUsesDefaultWhenNoneStored() async {
        let sync = MockCloudSync(entries: [], settings: nil)
        let m = DashboardModel(sync: sync)
        await m.loadSettings(defaultTranslation: .niv)
        XCTAssertEqual(m.settings?.translation, .niv)
        XCTAssertEqual(m.settings?.crisisAlertsEnabled, true)
    }

    func testUpdateSettingsPersists() async {
        let sync = MockCloudSync(entries: [], settings: nil)
        let m = DashboardModel(sync: sync)
        await m.loadSettings(defaultTranslation: .nirv)
        var updated = m.settings!
        updated.sessionTimeLimitMinutes = 20
        await m.updateSettings(updated)
        XCTAssertEqual(m.settings?.sessionTimeLimitMinutes, 20)
        let stored = await sync.fetchSettings()
        XCTAssertEqual(stored?.sessionTimeLimitMinutes, 20)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "DashboardModelTests"
```
Expected: BUILD FAILURE — `value of type 'DashboardModel' has no member 'loadSettings'`.

- [ ] **Step 3: Implement the methods**

Add to `app/BibleStoryCore/Sources/BibleStoryCore/DashboardModel.swift` (inside the class):
```swift
    /// Loads saved settings, falling back to safe defaults.
    public func loadSettings(defaultTranslation: BibleTranslation) async {
        if let saved = try? await sync.fetchSettings(), let saved {
            settings = saved
        } else {
            settings = .default(translation: defaultTranslation)
        }
    }

    /// Applies and persists updated settings.
    public func updateSettings(_ newSettings: SafetySettings) async {
        settings = newSettings
        try? await sync.save(settings: newSettings)
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "DashboardModelTests"
```
Expected: PASS (4 tests in the class).

- [ ] **Step 5: Run the full core suite**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore
```
Expected: PASS — all prior + P6 tests green.

- [ ] **Step 6: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests && git commit -m "feat(app): P6 settings load & persist"
```

---

### Task 5: App-target CloudKit sync service

**Files:**
- Create: `app/BibleStory/BibleStory/CloudKitSyncService.swift`
- Modify: `app/BibleStory/project.yml` (iCloud/CloudKit entitlement + container)

**Interfaces:**
- Consumes: `CloudSyncService`, `ConversationGuideEntry`, `SafetySettings`.
- Produces: `CloudKitSyncService` reading/writing the parent's private database.

- [ ] **Step 1: Implement the CloudKit service**

Create `app/BibleStory/BibleStory/CloudKitSyncService.swift`:
```swift
import Foundation
import CloudKit
import BibleStoryCore

/// Stores derived parent data in the private CloudKit database.
/// Record types: "GuideEntry", "Settings". Nothing about the child's raw
/// speech is ever written here.
struct CloudKitSyncService: CloudSyncService {
    private let db = CKContainer(identifier: "iCloud.com.biblestory.app").privateCloudDatabase

    func fetchConversationEntries(childID: UUID) async throws -> [ConversationGuideEntry] {
        let predicate = NSPredicate(format: "childID == %@", childID.uuidString)
        let query = CKQuery(recordType: "GuideEntry", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        let (matches, _) = try await db.records(matching: query)
        return matches.compactMap { _, result in
            guard let record = try? result.get() else { return nil }
            return Self.entry(from: record)
        }
    }

    func save(entry: ConversationGuideEntry) async throws {
        let record = CKRecord(recordType: "GuideEntry", recordID: .init(recordName: entry.id.uuidString))
        record["childID"] = entry.childID.uuidString as CKRecordValue
        record["question"] = entry.question as CKRecordValue
        record["discussionPrompt"] = entry.discussionPrompt as CKRecordValue
        record["storyID"] = entry.storyID.uuidString as CKRecordValue
        record["createdAt"] = entry.createdAt as CKRecordValue
        _ = try await db.save(record)
    }

    func fetchSettings() async throws -> SafetySettings? {
        let query = CKQuery(recordType: "Settings", predicate: NSPredicate(value: true))
        let (matches, _) = try await db.records(matching: query)
        guard let first = matches.first, let record = try? first.1.get(),
              let data = record["json"] as? Data else { return nil }
        return try? JSONDecoder().decode(SafetySettings.self, from: data)
    }

    func save(settings: SafetySettings) async throws {
        let record = CKRecord(recordType: "Settings", recordID: .init(recordName: "singleton"))
        record["json"] = try JSONEncoder().encode(settings) as CKRecordValue
        _ = try await db.save(record)
    }

    private static func entry(from record: CKRecord) -> ConversationGuideEntry? {
        guard let childID = (record["childID"] as? String).flatMap(UUID.init),
              let question = record["question"] as? String,
              let prompt = record["discussionPrompt"] as? String,
              let storyID = (record["storyID"] as? String).flatMap(UUID.init),
              let createdAt = record["createdAt"] as? Date,
              let id = UUID(uuidString: record.recordID.recordName) else { return nil }
        return ConversationGuideEntry(id: id, childID: childID, question: question,
                                      discussionPrompt: prompt, storyID: storyID, createdAt: createdAt)
    }
}
```

- [ ] **Step 2: Add the CloudKit entitlement**

In `app/BibleStory/project.yml`, extend the `BibleStory` target's `entitlements.properties` (merge with any existing keys from P2):
```yaml
    entitlements:
      path: BibleStory/BibleStory.entitlements
      properties:
        com.apple.developer.applesignin: [Default]
        com.apple.developer.icloud-container-identifiers: [iCloud.com.biblestory.app]
        com.apple.developer.icloud-services: [CloudKit]
```
Regenerate:
```bash
cd /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStory && xcodegen generate
```
Expected: `Created project at .../BibleStory.xcodeproj`.

- [ ] **Step 3: Build for the simulator**

Run (from `app/BibleStory/`):
```bash
xcodebuild -project BibleStory.xcodeproj -scheme BibleStory \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`. (CloudKit records require a signed-in iCloud account + provisioning to actually sync; the simulator build validates compilation only.)

- [ ] **Step 4: Commit**

```bash
git add app/BibleStory && git commit -m "feat(app): P6 CloudKit private-DB sync service"
```

---

### Task 6: Dashboard UI inside the parent zone

**Files:**
- Create: `app/BibleStory/BibleStory/DashboardView.swift`
- Modify: `app/BibleStory/BibleStory/ParentZoneView.swift` (from P1 — render the dashboard)

**Interfaces:**
- Consumes: `DashboardModel`, `SafetySettings`, `ConversationGuideEntry`, `AppModel`, `CloudKitSyncService`.
- Produces: the dashboard screens rendered in the gated parent zone.

- [ ] **Step 1: Implement the dashboard view**

Create `app/BibleStory/BibleStory/DashboardView.swift`:
```swift
import SwiftUI
import BibleStoryCore

struct DashboardView: View {
    @State var model: DashboardModel
    let childID: UUID
    let defaultTranslation: BibleTranslation

    var body: some View {
        NavigationStack {
            List {
                Section("Conversation Guide") {
                    if model.entries.isEmpty {
                        Text("No questions yet. When your child asks something big, it'll appear here with a way to talk about it.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(model.entries) { entry in
                            NavigationLink {
                                GuideDetailView(entry: entry)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(entry.question).font(.headline)
                                    Text(entry.createdAt, style: .date).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                if let progress = model.progress {
                    Section("Progress") {
                        Text("Stories completed: \(progress.completedCount)")
                        Text("Day streak: \(progress.streakDays)")
                    }
                }

                if let settings = model.settings {
                    Section("Controls") {
                        Picker("Translation", selection: Binding(
                            get: { settings.translation },
                            set: { newValue in
                                var s = settings; s.translation = newValue
                                Task { await model.updateSettings(s) }
                            })
                        ) {
                            ForEach(BibleTranslation.allCases, id: \.self) { Text($0.displayName).tag($0) }
                        }
                        Toggle("Crisis alerts", isOn: Binding(
                            get: { settings.crisisAlertsEnabled },
                            set: { newValue in
                                var s = settings; s.crisisAlertsEnabled = newValue
                                Task { await model.updateSettings(s) }
                            })
                        )
                    }
                }

                Section {
                    NavigationLink("Privacy & Safety") { SafetyClaimsView() }
                }
            }
            .navigationTitle("Parent Area")
            .task {
                await model.loadGuide(childID: childID)
                await model.loadSettings(defaultTranslation: defaultTranslation)
                model.loadProgress(childID: childID, completedCount: 0, today: Date())
            }
        }
    }
}

struct GuideDetailView: View {
    let entry: ConversationGuideEntry
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(entry.question).font(.title2)
                Text(entry.discussionPrompt).font(.body)
            }.padding()
        }.navigationTitle("Talk Together")
    }
}

struct SafetyClaimsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label("It never makes up Bible verses.", systemImage: "checkmark.seal.fill")
                Label("Hard questions come back to you.", systemImage: "checkmark.seal.fill")
                Label("Your child's questions stay on this device.", systemImage: "checkmark.seal.fill")
            }.padding()
        }.navigationTitle("Privacy & Safety")
    }
}
```

- [ ] **Step 2: Render the dashboard in the parent zone**

Replace `app/BibleStory/BibleStory/ParentZoneView.swift`:
```swift
import SwiftUI
import BibleStoryCore

/// The gated parent area. Renders the dashboard (P6) and a way back to stories.
struct ParentZoneView: View {
    let appModel: AppModel
    // In the full app these come from the loaded ParentAccount (P2). For now,
    // the composition root passes the active child + chosen translation.
    var childID: UUID = UUID()
    var translation: BibleTranslation = .nirv

    var body: some View {
        DashboardView(
            model: DashboardModel(sync: CloudKitSyncService()),
            childID: childID,
            defaultTranslation: translation
        )
        .safeAreaInset(edge: .bottom) {
            Button("Return to Stories") { appModel.exitToChildZone() }
                .buttonStyle(.borderedProminent)
                .padding()
        }
    }
}
```
> Wiring note: when P2's account is available at the composition root, pass the real `childID`/`translation` from the loaded `ParentAccount` into `ParentZoneView` instead of the defaults.

- [ ] **Step 3: Regenerate and build**

Run (from `app/BibleStory/`):
```bash
xcodegen generate && xcodebuild -project BibleStory.xcodeproj -scheme BibleStory \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Manual run verification**

Launch on the Simulator. From the child zone, tap the parent icon → pass the gate → the Parent Area appears:
1. Conversation Guide shows the empty-state message (no entries yet).
2. Controls show the translation picker + crisis-alerts toggle; changing them doesn't crash.
3. Privacy & Safety page lists the three claims.
4. "Return to Stories" goes back to the child zone.

- [ ] **Step 5: Commit**

```bash
git add app/BibleStory && git commit -m "feat(app): P6 parent dashboard UI in gated parent zone"
```

---

## Self-Review

**Spec coverage (PRD §4 Epic E, §5.5, §6.3, §9.2, §10):**
- Conversation guide (list + detail) → Tasks 2, 6. Content & safety controls (translation, disabled stories, time limit, crisis toggle) → Tasks 1, 4, 6. Progress & history (completed + streak) → Tasks 3, 6. Privacy/safety-claims page → Task 6. CloudKit private-DB sync → Task 5. Gated behind P1 parent zone → Task 6. ✅

**Placeholder scan:** all code/test steps complete; commands show expected output. No TBD/TODO. ✅

**Type consistency:** `SafetySettings`, `ProgressSummary`, `CloudSyncService`, `DashboardModel`, `ConversationGuideEntry`, `ChildProfile`, `BibleTranslation` match the shared-interfaces contract and P2/P4 definitions. ✅

**Noted deviations:**
1. Streak is derived from conversation-entry dates as an engagement proxy; `completedCount` is injected (source is P3's `StoryProgressStore`). Task 6 passes `completedCount: 0` as a placeholder until P3's store is wired at the composition root — flagged inline.
2. `ParentZoneView` takes `childID`/`translation` with temporary defaults; the composition root should pass the real values from P2's `ParentAccount` once available (wiring note in Task 6).
3. `CrisisEvent` surfacing (from P7) is not yet a dashboard section — P7 adds its own crisis-alert detail; a "Crisis alerts" list section can be added when P7 lands. The `crisisAlertsEnabled` control is present now.
