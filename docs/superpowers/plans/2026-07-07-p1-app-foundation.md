# P1 — App Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the iOS app skeleton with a Child zone and a Parent zone, where the Parent zone is reachable only by passing a parent gate (biometric/passcode) — the kid-mode lock — and all zone/gate logic is unit-tested.

**Architecture:** All zone-routing and gate logic lives in a platform-agnostic Swift Package (`BibleStoryCore`) that is unit-tested from the command line with `swift test` — no simulator needed, fast TDD cycles. The parent gate is a protocol so the core stays testable; the concrete biometric implementation and all SwiftUI views live in a thin iOS app target (`BibleStory`) that is verified by building and running. The app's single source of truth is an `@Observable` `AppModel` that owns the current `Zone`.

**Tech Stack:** Swift 6, SwiftUI, Observation framework, LocalAuthentication (biometrics), Swift Package Manager + XCTest. No third-party dependencies in P1.

## Global Constraints

_Every task's requirements implicitly include this section._

- **Deployment target:** iOS 17.0 minimum (enables the `@Observable` macro). Revisit against PRD Open Question Q6 before launch.
- **Language/tools:** `swift-tools-version: 6.0`; Swift 6 language mode.
- **UI:** SwiftUI + Observation only. No UIKit, no third-party packages in P1.
- **Kid-mode lock invariant (from PRD §5.1, §6.4 FR-12):** the Parent zone MUST be unreachable without a successful `ParentGate.authenticate()`. There is no code path that sets `zone = .parent` except after the gate returns `true`.
- **Layering:** all decision logic lives in the `BibleStoryCore` package and is unit-tested via `swift test`. SwiftUI views and biometrics live in the app target and are verified by build + manual run.
- **Privacy (PRD §10):** this layer processes no child input and stores no personal data; keep it that way.
- **Directory:** the iOS work lives under `app/` at the repo root, alongside the existing `data/`, `eval/`, `docs/`.

---

### Task 1: Core package scaffold + `Zone` type

**Files:**
- Create: `app/BibleStoryCore/Package.swift`
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/Zone.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/ZoneTests.swift`

**Interfaces:**
- Consumes: nothing (first task).
- Produces: `public enum Zone: Sendable, Equatable { case child; case parent }` — the two app zones, used by every later task and by the app target.

- [ ] **Step 1: Initialize the git repository (if not already one)**

Run (from repo root `bible-slm/`):
```bash
git rev-parse --is-inside-work-tree 2>/dev/null || git init
```
Expected: either prints `true`, or initializes an empty repository.

- [ ] **Step 2: Create the package manifest**

Create `app/BibleStoryCore/Package.swift`:
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BibleStoryCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BibleStoryCore", targets: ["BibleStoryCore"]),
    ],
    targets: [
        .target(name: "BibleStoryCore"),
        .testTarget(
            name: "BibleStoryCoreTests",
            dependencies: ["BibleStoryCore"]
        ),
    ]
)
```

- [ ] **Step 3: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/ZoneTests.swift`:
```swift
import XCTest
@testable import BibleStoryCore

final class ZoneTests: XCTestCase {
    func testChildAndParentAreDistinct() {
        XCTAssertNotEqual(Zone.child, Zone.parent)
    }
}
```

- [ ] **Step 4: Run test to verify it fails**

Run (from `app/BibleStoryCore/`):
```bash
swift test --filter "ZoneTests"
```
Expected: BUILD FAILURE — `cannot find 'Zone' in scope`.

- [ ] **Step 5: Implement `Zone`**

Create `app/BibleStoryCore/Sources/BibleStoryCore/Zone.swift`:
```swift
/// The two top-level areas of the app.
/// `.child` is the default, locked experience; `.parent` is gated.
public enum Zone: Sendable, Equatable {
    case child
    case parent
}
```

- [ ] **Step 6: Run test to verify it passes**

Run (from `app/BibleStoryCore/`):
```bash
swift test --filter "ZoneTests"
```
Expected: PASS — `Test Suite 'ZoneTests' passed`.

- [ ] **Step 7: Commit**

```bash
git add app/BibleStoryCore/Package.swift app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): scaffold BibleStoryCore package with Zone type"
```

---

### Task 2: `AppModel` defaults to the child zone

**Files:**
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/ParentGate.swift`
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/AppModel.swift`
- Create: `app/BibleStoryCore/Tests/BibleStoryCoreTests/TestDoubles.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/AppModelTests.swift`

**Interfaces:**
- Consumes: `Zone` (Task 1).
- Produces:
  - `public protocol ParentGate: Sendable { func authenticate() async -> Bool }`
  - `@MainActor @Observable public final class AppModel` with `public init(gate: ParentGate)` and `public private(set) var zone: Zone` (defaults to `.child`).
  - Test double `MockParentGate(result: Bool)` with `callCount`.

- [ ] **Step 1: Define the `ParentGate` protocol**

Create `app/BibleStoryCore/Sources/BibleStoryCore/ParentGate.swift`:
```swift
/// Presents the parent-authentication challenge (biometric / device passcode).
/// The core package depends only on this protocol so it stays testable;
/// the concrete implementation lives in the app target.
public protocol ParentGate: Sendable {
    /// Returns `true` iff the parent successfully authenticated.
    func authenticate() async -> Bool
}
```

- [ ] **Step 2: Add the test double**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/TestDoubles.swift`:
```swift
@testable import BibleStoryCore

/// A gate that returns a fixed result immediately, counting calls.
final class MockParentGate: ParentGate, @unchecked Sendable {
    let result: Bool
    private(set) var callCount = 0

    init(result: Bool) {
        self.result = result
    }

    func authenticate() async -> Bool {
        callCount += 1
        return result
    }
}
```

- [ ] **Step 3: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/AppModelTests.swift`:
```swift
import XCTest
@testable import BibleStoryCore

@MainActor
final class AppModelTests: XCTestCase {
    func testStartsInChildZone() {
        let model = AppModel(gate: MockParentGate(result: true))
        XCTAssertEqual(model.zone, .child)
    }
}
```

- [ ] **Step 4: Run test to verify it fails**

Run (from `app/BibleStoryCore/`):
```bash
swift test --filter "AppModelTests"
```
Expected: BUILD FAILURE — `cannot find 'AppModel' in scope`.

- [ ] **Step 5: Implement the `AppModel` skeleton**

Create `app/BibleStoryCore/Sources/BibleStoryCore/AppModel.swift`:
```swift
import Observation

/// Single source of truth for which zone the app is showing.
@MainActor
@Observable
public final class AppModel {
    /// The currently displayed zone. Only this type may change it.
    public private(set) var zone: Zone = .child

    private let gate: ParentGate

    public init(gate: ParentGate) {
        self.gate = gate
    }
}
```

- [ ] **Step 6: Run test to verify it passes**

Run (from `app/BibleStoryCore/`):
```bash
swift test --filter "AppModelTests"
```
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): add AppModel defaulting to child zone + ParentGate protocol"
```

---

### Task 3: `enterParentZone()` — success path

**Files:**
- Modify: `app/BibleStoryCore/Sources/BibleStoryCore/AppModel.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/AppModelTests.swift`

**Interfaces:**
- Consumes: `AppModel`, `ParentGate`, `MockParentGate` (Task 2).
- Produces: `public func enterParentZone() async` on `AppModel` — awaits the gate; on `true`, sets `zone = .parent`.

- [ ] **Step 1: Write the failing test**

Add to `AppModelTests` in `app/BibleStoryCore/Tests/BibleStoryCoreTests/AppModelTests.swift`:
```swift
    func testEnterParentZoneSucceedsWhenGatePasses() async {
        let gate = MockParentGate(result: true)
        let model = AppModel(gate: gate)

        await model.enterParentZone()

        XCTAssertEqual(model.zone, .parent)
        XCTAssertEqual(gate.callCount, 1)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run (from `app/BibleStoryCore/`):
```bash
swift test --filter "AppModelTests/testEnterParentZoneSucceedsWhenGatePasses"
```
Expected: BUILD FAILURE — `value of type 'AppModel' has no member 'enterParentZone'`.

- [ ] **Step 3: Implement `enterParentZone()`**

Update `app/BibleStoryCore/Sources/BibleStoryCore/AppModel.swift` to the full file below:
```swift
import Observation

/// Single source of truth for which zone the app is showing.
@MainActor
@Observable
public final class AppModel {
    /// The currently displayed zone. Only this type may change it.
    public private(set) var zone: Zone = .child

    private let gate: ParentGate

    public init(gate: ParentGate) {
        self.gate = gate
    }

    /// Attempts to move from the child zone into the parent zone.
    /// Requires passing the parent gate — the kid-mode lock.
    public func enterParentZone() async {
        let didAuthenticate = await gate.authenticate()
        if didAuthenticate {
            zone = .parent
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run (from `app/BibleStoryCore/`):
```bash
swift test --filter "AppModelTests/testEnterParentZoneSucceedsWhenGatePasses"
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): enterParentZone switches to parent zone when gate passes"
```

---

### Task 4: `enterParentZone()` — failure path (kid-mode lock)

**Files:**
- Modify: `app/BibleStoryCore/Sources/BibleStoryCore/AppModel.swift` (no code change expected — this task proves the invariant)
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/AppModelTests.swift`

**Interfaces:**
- Consumes: `AppModel`, `MockParentGate` (Tasks 2–3).
- Produces: verified guarantee that a failed gate leaves `zone == .child`.

- [ ] **Step 1: Write the failing test**

Add to `AppModelTests`:
```swift
    func testEnterParentZoneStaysInChildZoneWhenGateFails() async {
        let gate = MockParentGate(result: false)
        let model = AppModel(gate: gate)

        await model.enterParentZone()

        XCTAssertEqual(model.zone, .child)   // kid-mode lock holds
        XCTAssertEqual(gate.callCount, 1)
    }
```

- [ ] **Step 2: Run test to verify it passes (or fails)**

Run (from `app/BibleStoryCore/`):
```bash
swift test --filter "AppModelTests/testEnterParentZoneStaysInChildZoneWhenGateFails"
```
Expected: PASS immediately — the Task 3 implementation already only switches on `true`. This test locks the invariant so a future change can't silently break it. If it FAILS, the guard in `enterParentZone()` is wrong; fix `AppModel` so `zone` changes only when `didAuthenticate` is `true`.

- [ ] **Step 3: Commit**

```bash
git add app/BibleStoryCore/Tests
git commit -m "test(app): lock kid-mode invariant — failed gate stays in child zone"
```

---

### Task 5: `exitToChildZone()`

**Files:**
- Modify: `app/BibleStoryCore/Sources/BibleStoryCore/AppModel.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/AppModelTests.swift`

**Interfaces:**
- Consumes: `AppModel` (Tasks 2–3).
- Produces: `public func exitToChildZone()` on `AppModel` — sets `zone = .child` unconditionally (leaving the parent area needs no gate).

- [ ] **Step 1: Write the failing test**

Add to `AppModelTests`:
```swift
    func testExitToChildZoneReturnsToChild() async {
        let model = AppModel(gate: MockParentGate(result: true))
        await model.enterParentZone()
        XCTAssertEqual(model.zone, .parent)   // precondition

        model.exitToChildZone()

        XCTAssertEqual(model.zone, .child)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run (from `app/BibleStoryCore/`):
```bash
swift test --filter "AppModelTests/testExitToChildZoneReturnsToChild"
```
Expected: BUILD FAILURE — `value of type 'AppModel' has no member 'exitToChildZone'`.

- [ ] **Step 3: Implement `exitToChildZone()`**

Update `app/BibleStoryCore/Sources/BibleStoryCore/AppModel.swift` to the full file below:
```swift
import Observation

/// Single source of truth for which zone the app is showing.
@MainActor
@Observable
public final class AppModel {
    /// The currently displayed zone. Only this type may change it.
    public private(set) var zone: Zone = .child

    private let gate: ParentGate

    public init(gate: ParentGate) {
        self.gate = gate
    }

    /// Attempts to move from the child zone into the parent zone.
    /// Requires passing the parent gate — the kid-mode lock.
    public func enterParentZone() async {
        let didAuthenticate = await gate.authenticate()
        if didAuthenticate {
            zone = .parent
        }
    }

    /// Returns to the child zone. Always allowed — no gate needed to leave.
    public func exitToChildZone() {
        zone = .child
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run (from `app/BibleStoryCore/`):
```bash
swift test --filter "AppModelTests/testExitToChildZoneReturnsToChild"
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): exitToChildZone returns to the child zone"
```

---

### Task 6: Re-entrancy guard + `isAuthenticating` state

Prevents a child mashing the parent button from launching multiple overlapping gate prompts, and exposes an `isAuthenticating` flag the UI can use to disable the button / show a spinner.

**Files:**
- Modify: `app/BibleStoryCore/Sources/BibleStoryCore/AppModel.swift`
- Modify: `app/BibleStoryCore/Tests/BibleStoryCoreTests/TestDoubles.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/AppModelTests.swift`

**Interfaces:**
- Consumes: `AppModel`, `ParentGate` (Tasks 2–5).
- Produces:
  - `public private(set) var isAuthenticating: Bool` on `AppModel` (defaults `false`).
  - `enterParentZone()` now no-ops if already authenticating or already in the parent zone.
  - Test double `ControllableParentGate` with `authenticate()` that suspends until `complete(with:)` is called, plus `callCount`.

- [ ] **Step 1: Add the controllable test double**

Add to `app/BibleStoryCore/Tests/BibleStoryCoreTests/TestDoubles.swift`:
```swift
import Foundation

/// A gate whose `authenticate()` stays suspended until the test calls
/// `complete(with:)`, so we can observe the in-flight state deterministically.
@MainActor
final class ControllableParentGate: ParentGate {
    private(set) var callCount = 0
    private var continuation: CheckedContinuation<Bool, Never>?

    nonisolated init() {}

    func authenticate() async -> Bool {
        callCount += 1
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func complete(with result: Bool) {
        continuation?.resume(returning: result)
        continuation = nil
    }
}
```
Note: `ControllableParentGate` is `@MainActor`; `authenticate()` therefore runs on the main actor, matching `AppModel`. `ParentGate.authenticate()` is `async`, so a `@MainActor` conformance is legal.

- [ ] **Step 2: Write the failing test**

Add to `AppModelTests`:
```swift
    func testConcurrentEnterIsGuarded() async {
        let gate = ControllableParentGate()
        let model = AppModel(gate: gate)

        // Start the first attempt but do not await it — it suspends in the gate.
        async let firstAttempt: Void = model.enterParentZone()
        // Let the first attempt reach the gate's suspension point.
        await Task.yield()

        XCTAssertTrue(model.isAuthenticating)
        XCTAssertEqual(gate.callCount, 1)

        // A second attempt while authenticating must be ignored.
        await model.enterParentZone()
        XCTAssertEqual(gate.callCount, 1, "second attempt should be a no-op")

        // Finish the first attempt.
        gate.complete(with: true)
        await firstAttempt

        XCTAssertEqual(model.zone, .parent)
        XCTAssertFalse(model.isAuthenticating)
    }
```

- [ ] **Step 3: Run test to verify it fails**

Run (from `app/BibleStoryCore/`):
```bash
swift test --filter "AppModelTests/testConcurrentEnterIsGuarded"
```
Expected: BUILD FAILURE — `value of type 'AppModel' has no member 'isAuthenticating'`.

- [ ] **Step 4: Implement the guard + flag**

Update `app/BibleStoryCore/Sources/BibleStoryCore/AppModel.swift` to the full file below:
```swift
import Observation

/// Single source of truth for which zone the app is showing.
@MainActor
@Observable
public final class AppModel {
    /// The currently displayed zone. Only this type may change it.
    public private(set) var zone: Zone = .child

    /// True while a parent-gate challenge is in flight (for UI + re-entrancy).
    public private(set) var isAuthenticating: Bool = false

    private let gate: ParentGate

    public init(gate: ParentGate) {
        self.gate = gate
    }

    /// Attempts to move from the child zone into the parent zone.
    /// Requires passing the parent gate — the kid-mode lock.
    /// No-ops if already in the parent zone or a challenge is already running.
    public func enterParentZone() async {
        guard zone == .child, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let didAuthenticate = await gate.authenticate()
        if didAuthenticate {
            zone = .parent
        }
    }

    /// Returns to the child zone. Always allowed — no gate needed to leave.
    public func exitToChildZone() {
        zone = .child
    }
}
```

- [ ] **Step 5: Run the full core test suite to verify everything passes**

Run (from `app/BibleStoryCore/`):
```bash
swift test
```
Expected: PASS — all tests in `ZoneTests` and `AppModelTests` green.

- [ ] **Step 6: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests
git commit -m "feat(app): guard re-entrant parent-gate attempts, expose isAuthenticating"
```

---

### Task 7: iOS app shell — routing, biometric gate, placeholder zone views

This task creates the Xcode app target that consumes `BibleStoryCore`. SwiftUI views and biometrics are verified by building and running in the Simulator, not by `swift test`.

**Files:**
- Create (via Xcode): `app/BibleStory/BibleStory.xcodeproj` and target `BibleStory`
- Create: `app/BibleStory/BibleStory/BibleStoryApp.swift`
- Create: `app/BibleStory/BibleStory/RootView.swift`
- Create: `app/BibleStory/BibleStory/ChildZoneView.swift`
- Create: `app/BibleStory/BibleStory/ParentZoneView.swift`
- Create: `app/BibleStory/BibleStory/BiometricParentGate.swift`
- Modify (via Xcode): target Info settings — add `NSFaceIDUsageDescription`

**Interfaces:**
- Consumes: `AppModel`, `Zone`, `ParentGate` (from `BibleStoryCore`).
- Produces: a runnable app whose root switches on `AppModel.zone`, with `BiometricParentGate` as the concrete `ParentGate`.

- [ ] **Step 1: Create the Xcode app project**

In Xcode: File ▸ New ▸ Project ▸ iOS ▸ App. Product Name `BibleStory`, Interface **SwiftUI**, Language **Swift**. Save it at `app/BibleStory/`. In the target's General settings, set **Minimum Deployments = iOS 17.0**.

- [ ] **Step 2: Add the local core package to the app**

In Xcode: File ▸ Add Package Dependencies… ▸ Add Local… ▸ select `app/BibleStoryCore`. Then in the `BibleStory` target ▸ General ▸ Frameworks, Libraries, and Embedded Content, confirm `BibleStoryCore` is listed.

- [ ] **Step 3: Add the Face ID usage string**

In Xcode: select the `BibleStory` target ▸ Info tab ▸ add key **Privacy - Face ID Usage Description** (`NSFaceIDUsageDescription`) with value: `Confirm you're a grown-up to open the parent area.`

- [ ] **Step 4: Write the concrete biometric gate**

Replace/create `app/BibleStory/BibleStory/BiometricParentGate.swift`:
```swift
import Foundation
import LocalAuthentication
import BibleStoryCore

/// Concrete parent gate backed by Face ID / Touch ID, with automatic
/// device-passcode fallback. Returns false on any failure or cancellation.
final class BiometricParentGate: ParentGate {
    func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Enter Passcode"

        let policy: LAPolicy = .deviceOwnerAuthentication
        var policyError: NSError?
        guard context.canEvaluatePolicy(policy, error: &policyError) else {
            return false
        }

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(
                policy,
                localizedReason: "Confirm you're a grown-up to open the parent area."
            ) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
```

- [ ] **Step 5: Write the app entry point**

Replace `app/BibleStory/BibleStory/BibleStoryApp.swift`:
```swift
import SwiftUI
import BibleStoryCore

@main
struct BibleStoryApp: App {
    @State private var appModel = AppModel(gate: BiometricParentGate())

    var body: some Scene {
        WindowGroup {
            RootView(appModel: appModel)
        }
    }
}
```

- [ ] **Step 6: Write the root router**

Create `app/BibleStory/BibleStory/RootView.swift`:
```swift
import SwiftUI
import BibleStoryCore

struct RootView: View {
    let appModel: AppModel

    var body: some View {
        switch appModel.zone {
        case .child:
            ChildZoneView(appModel: appModel)
        case .parent:
            ParentZoneView(appModel: appModel)
        }
    }
}
```

- [ ] **Step 7: Write the child-zone placeholder (with gated parent entry)**

Create `app/BibleStory/BibleStory/ChildZoneView.swift`:
```swift
import SwiftUI
import BibleStoryCore

/// Placeholder for the child experience (Story Library arrives in Plan P3).
/// The only way out to the parent area is through the gated button.
struct ChildZoneView: View {
    let appModel: AppModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Spacer()
                Text("Story Library")
                    .font(.largeTitle)
                Spacer()
            }

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

- [ ] **Step 8: Write the parent-zone placeholder**

Create `app/BibleStory/BibleStory/ParentZoneView.swift`:
```swift
import SwiftUI
import BibleStoryCore

/// Placeholder for the parent dashboard (built out in Plan P6).
struct ParentZoneView: View {
    let appModel: AppModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Parent Dashboard")
                .font(.largeTitle)
            Button("Return to Stories") {
                appModel.exitToChildZone()
            }
        }
    }
}
```

- [ ] **Step 9: Build the app for the Simulator**

Run (from `app/BibleStory/`):
```bash
xcodebuild -project BibleStory.xcodeproj -scheme BibleStory \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```
Expected: `** BUILD SUCCEEDED **`. (If the named simulator doesn't exist, list options with `xcrun simctl list devices` and substitute a name.)

- [ ] **Step 10: Manual run verification**

Run the app in the Simulator (Xcode ▸ Run, or launch the built app). In the Simulator, enable Features ▸ Face ID ▸ Enrolled. Then verify this checklist:
1. App launches into the **child zone** — "Story Library" is shown with a small parent icon in the top-right corner.
2. Tap the parent icon → a Face ID prompt appears. Trigger Features ▸ Face ID ▸ **Matching Face** → the screen switches to **"Parent Dashboard"**.
3. From the dashboard, tap **Return to Stories** → back to the child zone.
4. Tap the parent icon again → this time trigger Features ▸ Face ID ▸ **Non-matching Face** → you remain in the **child zone** (kid-mode lock holds).

- [ ] **Step 11: Commit**

```bash
git add app/BibleStory
git commit -m "feat(app): iOS app shell — zone routing + biometric parent gate"
```

---

## Self-Review

**Spec coverage (against PRD §5.1, §6.4, §8):**
- Kid-mode lock / parent gate (FR-12, §5.1 step 7) → Tasks 3, 4, 6, 7. ✅
- Child zone vs Parent zone routing (§8 "Two zones") → Tasks 1, 2, 7. ✅
- App state single source of truth → `AppModel`, Tasks 2–6. ✅
- Onboarding, story library, dashboard contents → intentionally **out of P1** (Plans P2, P3, P6); placeholders only. Noted, not a gap.

**Placeholder scan:** No "TBD/TODO/handle appropriately" in steps; every code and test step shows complete code and an exact command with expected output. ✅

**Type consistency:** `Zone.child`/`.parent`, `ParentGate.authenticate() async -> Bool`, `AppModel(gate:)`, `zone`, `isAuthenticating`, `enterParentZone()`, `exitToChildZone()` are used identically across Tasks 1–7 and both test doubles. ✅
