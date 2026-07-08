# P2 — Accounts & Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first-run onboarding wizard (welcome → Sign in with Apple → child profile → Bible translation → safety setup → free-trial paywall → parent-gate setup → hand-off) and the account layer behind it, so a parent can set up the app and it remembers them.

**Architecture:** All wizard logic — step progression, validation, and the account draft — lives in `BibleStoryCore` as `OnboardingModel` and `AccountModel`, tested against mock `AuthenticationService` / `SubscriptionService` / `AccountStore`. The Apple-framework implementations (`SignInWithAppleService`, `StoreKitSubscriptionService`, `KeychainAccountStore`) and the SwiftUI wizard screens live in the app target, verified by build + manual run. The app shows onboarding when `AccountStore.load()` returns `nil`, otherwise the P1 child zone.

**Tech Stack:** Swift 6, SwiftUI, Observation, AuthenticationServices (Sign in with Apple), StoreKit 2, Security (Keychain), XCTest.

## Global Constraints

_Every task's requirements implicitly include this section._

- **Deployment target:** iOS 17.0. **Tools:** `swift-tools-version: 6.0`, Swift 6 language mode.
- **UI:** SwiftUI + Observation. No third-party packages.
- **Layering:** decision logic in `BibleStoryCore` (`swift test`); Apple-framework glue in the `BibleStory` app target (build + manual). Regenerate the Xcode project with `xcodegen generate` (from `app/BibleStory/`); `project.yml` is the source of truth.
- **COPPA (PRD §10):** collect no child PII beyond a parent-chosen name + age; verifiable parental consent happens at onboarding; no third-party ad SDKs.
- **Monetization (PRD §12):** auto-renewing subscription with a free trial; no ads.
- **Kid-mode lock (P1):** onboarding ends by confirming the parent gate; the hand-off screen precedes dropping into the child zone.
- **StoreKit / Sign in with Apple can't be unit-tested in the package** — keep them behind the protocols; the trial/status *decision* logic lives in the testable model layer.
- **Canonical types:** this plan OWNS `BibleTranslation`, `ChildProfile`, `SubscriptionStatus`, `ParentAccount`, `OnboardingStep` (per the shared-interfaces contract). If P4 added a temporary `BibleTranslation` shim, delete it here.
- Existing types available: P1 (`AppModel`, `Zone`, `ParentGate`, `BiometricParentGate`).

---

### Task 1: Account domain types

**Files:**
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/AccountTypes.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/AccountTypesTests.swift`

**Interfaces:**
- Produces: `BibleTranslation`, `ChildProfile`, `SubscriptionStatus`, `ParentAccount`, `OnboardingStep` exactly per the shared-interfaces contract.

> If P4 created a temporary `BibleTranslation.swift` shim, delete that file as part of Step 3 so this file is the single definition.

- [ ] **Step 1: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/AccountTypesTests.swift`:
```swift
import XCTest
@testable import BibleStoryCore

final class AccountTypesTests: XCTestCase {
    func testTranslationDisplayNames() {
        XCTAssertEqual(BibleTranslation.nirv.displayName, "NIrV")
        XCTAssertEqual(BibleTranslation.kjv.displayName, "KJV")
        XCTAssertEqual(BibleTranslation.allCases.count, 5)
    }

    func testParentAccountRoundTripsCodable() throws {
        let account = ParentAccount(
            appleUserID: "abc123",
            children: [ChildProfile(id: UUID(), name: "Micah", age: 8)],
            translation: .esv,
            subscription: .trial
        )
        let data = try JSONEncoder().encode(account)
        let decoded = try JSONDecoder().decode(ParentAccount.self, from: data)
        XCTAssertEqual(decoded, account)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "AccountTypesTests"
```
Expected: BUILD FAILURE — `cannot find 'BibleTranslation' in scope` (or a redeclaration error if the P4 shim still exists — delete it in Step 3).

- [ ] **Step 3: Implement the types**

If a `app/BibleStoryCore/Sources/BibleStoryCore/BibleTranslation.swift` shim exists from P4, delete it. Create `app/BibleStoryCore/Sources/BibleStoryCore/AccountTypes.swift`:
```swift
import Foundation

public enum BibleTranslation: String, CaseIterable, Sendable, Codable {
    case nirv, icb, esv, niv, kjv

    public var displayName: String {
        switch self {
        case .nirv: return "NIrV"
        case .icb:  return "ICB"
        case .esv:  return "ESV"
        case .niv:  return "NIV"
        case .kjv:  return "KJV"
        }
    }
}

public struct ChildProfile: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var age: Int          // intended 7...9; out-of-band handled per PRD Q2

    public init(id: UUID, name: String, age: Int) {
        self.id = id
        self.name = name
        self.age = age
    }
}

public enum SubscriptionStatus: Sendable, Equatable, Codable {
    case none, trial, active, expired
}

public struct ParentAccount: Sendable, Codable, Equatable {
    public let appleUserID: String
    public var children: [ChildProfile]
    public var translation: BibleTranslation
    public var subscription: SubscriptionStatus

    public init(
        appleUserID: String,
        children: [ChildProfile],
        translation: BibleTranslation,
        subscription: SubscriptionStatus
    ) {
        self.appleUserID = appleUserID
        self.children = children
        self.translation = translation
        self.subscription = subscription
    }
}

/// The onboarding wizard steps, in order.
public enum OnboardingStep: Int, Sendable, Equatable, CaseIterable {
    case welcome, signIn, childProfile, translation, safetySetup, paywall, parentGateSetup, handoff, done
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "AccountTypesTests"
```
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests && git commit -m "feat(app): P2 account domain types"
```

---

### Task 2: Onboarding services + `OnboardingModel` step progression

**Files:**
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/OnboardingServices.swift`
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/OnboardingModel.swift`
- Modify: `app/BibleStoryCore/Tests/BibleStoryCoreTests/TestDoubles.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/OnboardingModelTests.swift`

**Interfaces:**
- Produces:
  - `protocol AuthenticationService { func signInWithApple() async throws -> String }`
  - `protocol SubscriptionService { func currentStatus() async -> SubscriptionStatus; func startFreeTrial() async throws; func restore() async throws -> SubscriptionStatus }`
  - `protocol AccountStore { func load() async -> ParentAccount?; func save(_:) async }`
  - `@MainActor @Observable final class OnboardingModel` with `step`, editable `childName`/`childAge`/`translation`, `canAdvance`, `advance()`, `back()`, `isComplete`.
  - Test doubles `MockAuth`, `MockSubscriptions`, `InMemoryAccountStore`.

- [ ] **Step 1: Add test doubles**

Add to `app/BibleStoryCore/Tests/BibleStoryCoreTests/TestDoubles.swift`:
```swift
// MARK: - P2 test doubles

final class MockAuth: AuthenticationService, @unchecked Sendable {
    var userID: String? = "apple-user-1"
    struct Failure: Error {}
    func signInWithApple() async throws -> String {
        guard let userID else { throw Failure() }
        return userID
    }
}

final class MockSubscriptions: SubscriptionService, @unchecked Sendable {
    var status: SubscriptionStatus = .none
    var trialSucceeds = true
    struct Failure: Error {}
    func currentStatus() async -> SubscriptionStatus { status }
    func startFreeTrial() async throws {
        guard trialSucceeds else { throw Failure() }
        status = .trial
    }
    func restore() async throws -> SubscriptionStatus { status }
}

actor InMemoryAccountStore: AccountStore {
    private var stored: ParentAccount?
    init(seed: ParentAccount? = nil) { self.stored = seed }
    func load() async -> ParentAccount? { stored }
    func save(_ account: ParentAccount) async { stored = account }
}
```

- [ ] **Step 2: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/OnboardingModelTests.swift`:
```swift
import XCTest
@testable import BibleStoryCore

@MainActor
final class OnboardingModelTests: XCTestCase {
    private func make() -> OnboardingModel {
        OnboardingModel(auth: MockAuth(), subscriptions: MockSubscriptions())
    }

    func testStartsAtWelcome() {
        XCTAssertEqual(make().step, .welcome)
    }

    func testAdvanceFromWelcomeGoesToSignIn() {
        let m = make()
        m.advance()
        XCTAssertEqual(m.step, .signIn)
    }

    func testCannotAdvancePastSignInWithoutAppleID() {
        let m = make()
        m.advance()                 // welcome -> signIn
        XCTAssertFalse(m.canAdvance)
        m.advance()                 // blocked
        XCTAssertEqual(m.step, .signIn)
    }

    func testChildProfileRequiresNonEmptyName() {
        let m = make()
        m.step = .childProfile
        m.childName = "   "
        XCTAssertFalse(m.canAdvance)
        m.childName = "Micah"
        XCTAssertTrue(m.canAdvance)
    }

    func testBackMovesToPreviousStep() {
        let m = make()
        m.step = .translation
        m.back()
        XCTAssertEqual(m.step, .childProfile)
    }
}
```

- [ ] **Step 3: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "OnboardingModelTests"
```
Expected: BUILD FAILURE — `cannot find 'OnboardingModel' in scope`.

- [ ] **Step 4: Implement the services and model**

Create `app/BibleStoryCore/Sources/BibleStoryCore/OnboardingServices.swift`:
```swift
/// Sign in with Apple (concrete impl in the app target).
public protocol AuthenticationService: Sendable {
    /// Returns a stable Apple user identifier on success.
    func signInWithApple() async throws -> String
}

/// StoreKit 2 subscription (concrete impl in the app target).
public protocol SubscriptionService: Sendable {
    func currentStatus() async -> SubscriptionStatus
    func startFreeTrial() async throws
    func restore() async throws -> SubscriptionStatus
}

/// Persists the parent account (Keychain in the app target).
public protocol AccountStore: Sendable {
    func load() async -> ParentAccount?
    func save(_ account: ParentAccount) async
}
```

Create `app/BibleStoryCore/Sources/BibleStoryCore/OnboardingModel.swift`:
```swift
import Observation

/// Drives the first-run onboarding wizard and collects the account draft.
@MainActor
@Observable
public final class OnboardingModel {
    public private(set) var step: OnboardingStep = .welcome

    // Editable draft fields (bound by the wizard screens).
    public var childName: String = ""
    public var childAge: Int = 7
    public var translation: BibleTranslation = .nirv

    // Filled by service calls.
    public private(set) var appleUserID: String?
    public private(set) var subscription: SubscriptionStatus = .none

    private let auth: AuthenticationService
    private let subscriptions: SubscriptionService

    public init(auth: AuthenticationService, subscriptions: SubscriptionService) {
        self.auth = auth
        self.subscriptions = subscriptions
    }

    /// Whether the current step's requirements are satisfied.
    public var canAdvance: Bool {
        switch step {
        case .signIn:
            return appleUserID != nil
        case .childProfile:
            return !childName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && childAge > 0
        case .paywall:
            return subscription == .trial || subscription == .active
        case .done:
            return false
        default:
            return true
        }
    }

    public func advance() {
        guard canAdvance, let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    public func back() {
        guard let prev = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        step = prev
    }

    public var isComplete: Bool { step == .done }

    /// Performs Sign in with Apple, then advances if on the sign-in step.
    public func signIn() async {
        if let id = try? await auth.signInWithApple() {
            appleUserID = id
            if step == .signIn { advance() }
        }
    }

    /// Starts the free trial, then advances if on the paywall step.
    public func startTrial() async {
        try? await subscriptions.startFreeTrial()
        subscription = await subscriptions.currentStatus()
        if step == .paywall { advance() }
    }

    /// Builds the finished account (nil until sign-in has produced an id).
    public func makeAccount() -> ParentAccount? {
        guard let appleUserID else { return nil }
        let child = ChildProfile(id: UUID(), name: childName.trimmingCharacters(in: .whitespacesAndNewlines), age: childAge)
        return ParentAccount(
            appleUserID: appleUserID,
            children: [child],
            translation: translation,
            subscription: subscription
        )
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "OnboardingModelTests"
```
Expected: PASS (5 tests).

- [ ] **Step 6: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests && git commit -m "feat(app): P2 onboarding services + step progression"
```

---

### Task 3: `OnboardingModel` — sign-in and trial gating

**Files:**
- Modify: `app/BibleStoryCore/Tests/BibleStoryCoreTests/OnboardingModelTests.swift`

**Interfaces:**
- Consumes: `OnboardingModel`, `MockAuth`, `MockSubscriptions` (Task 2). Locks the async-gated transitions.

- [ ] **Step 1: Write the failing/locking tests**

Add to `OnboardingModelTests`:
```swift
    func testSignInSuccessAdvancesToChildProfile() async {
        let m = OnboardingModel(auth: MockAuth(), subscriptions: MockSubscriptions())
        m.step = .signIn
        await m.signIn()
        XCTAssertEqual(m.appleUserID, "apple-user-1")
        XCTAssertEqual(m.step, .childProfile)
    }

    func testSignInFailureStaysOnSignIn() async {
        let auth = MockAuth(); auth.userID = nil
        let m = OnboardingModel(auth: auth, subscriptions: MockSubscriptions())
        m.step = .signIn
        await m.signIn()
        XCTAssertNil(m.appleUserID)
        XCTAssertEqual(m.step, .signIn)
    }

    func testStartTrialSuccessAdvancesPastPaywall() async {
        let m = OnboardingModel(auth: MockAuth(), subscriptions: MockSubscriptions())
        m.step = .paywall
        await m.startTrial()
        XCTAssertEqual(m.subscription, .trial)
        XCTAssertEqual(m.step, .parentGateSetup)
    }

    func testStartTrialFailureStaysOnPaywall() async {
        let subs = MockSubscriptions(); subs.trialSucceeds = false
        let m = OnboardingModel(auth: MockAuth(), subscriptions: subs)
        m.step = .paywall
        await m.startTrial()
        XCTAssertEqual(m.subscription, .none)
        XCTAssertEqual(m.step, .paywall)
    }
```

- [ ] **Step 2: Run tests to verify they pass**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "OnboardingModelTests"
```
Expected: PASS — Task 2's `signIn()`/`startTrial()` already implement this gating. If any FAIL, ensure `signIn()`/`startTrial()` only `advance()` after a successful service call and set the correct fields.

- [ ] **Step 3: Commit**

```bash
git add app/BibleStoryCore/Tests && git commit -m "test(app): P2 lock sign-in and trial gating"
```

---

### Task 4: `AccountModel` — persistence and edits

**Files:**
- Create: `app/BibleStoryCore/Sources/BibleStoryCore/AccountModel.swift`
- Test: `app/BibleStoryCore/Tests/BibleStoryCoreTests/AccountModelTests.swift`

**Interfaces:**
- Consumes: `ParentAccount`, `ChildProfile`, `BibleTranslation`, `AccountStore`, `InMemoryAccountStore` (Task 2).
- Produces: `@MainActor @Observable final class AccountModel` with `account: ParentAccount?`, `load() async`, `establish(_:) async`, `addChild(name:age:) async`, `setTranslation(_:) async`.

- [ ] **Step 1: Write the failing test**

Create `app/BibleStoryCore/Tests/BibleStoryCoreTests/AccountModelTests.swift`:
```swift
import XCTest
@testable import BibleStoryCore

@MainActor
final class AccountModelTests: XCTestCase {
    private func seedAccount() -> ParentAccount {
        ParentAccount(
            appleUserID: "u1",
            children: [ChildProfile(id: UUID(), name: "Micah", age: 8)],
            translation: .nirv,
            subscription: .trial
        )
    }

    func testLoadPopulatesFromStore() async {
        let store = InMemoryAccountStore(seed: seedAccount())
        let m = AccountModel(store: store)
        await m.load()
        XCTAssertEqual(m.account?.appleUserID, "u1")
    }

    func testAddChildPersists() async {
        let store = InMemoryAccountStore(seed: seedAccount())
        let m = AccountModel(store: store)
        await m.load()
        await m.addChild(name: "Ada", age: 7)
        XCTAssertEqual(m.account?.children.count, 2)
        let reloaded = await store.load()
        XCTAssertEqual(reloaded?.children.count, 2)
    }

    func testSetTranslationPersists() async {
        let store = InMemoryAccountStore(seed: seedAccount())
        let m = AccountModel(store: store)
        await m.load()
        await m.setTranslation(.esv)
        XCTAssertEqual(m.account?.translation, .esv)
        let reloaded = await store.load()
        XCTAssertEqual(reloaded?.translation, .esv)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "AccountModelTests"
```
Expected: BUILD FAILURE — `cannot find 'AccountModel' in scope`.

- [ ] **Step 3: Implement `AccountModel`**

Create `app/BibleStoryCore/Sources/BibleStoryCore/AccountModel.swift`:
```swift
import Foundation
import Observation

/// Holds the persisted parent account and applies edits, writing through the store.
@MainActor
@Observable
public final class AccountModel {
    public private(set) var account: ParentAccount?

    private let store: AccountStore

    public init(store: AccountStore) {
        self.store = store
    }

    public func load() async {
        account = await store.load()
    }

    /// Sets the initial account (e.g. right after onboarding) and persists it.
    public func establish(_ account: ParentAccount) async {
        self.account = account
        await store.save(account)
    }

    public func addChild(name: String, age: Int) async {
        guard var account else { return }
        account.children.append(ChildProfile(id: UUID(), name: name, age: age))
        self.account = account
        await store.save(account)
    }

    public func setTranslation(_ translation: BibleTranslation) async {
        guard var account else { return }
        account.translation = translation
        self.account = account
        await store.save(account)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore --filter "AccountModelTests"
```
Expected: PASS (3 tests).

- [ ] **Step 5: Run the full core suite**

Run:
```bash
swift test --package-path /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStoryCore
```
Expected: PASS — all prior + P2 tests green.

- [ ] **Step 6: Commit**

```bash
git add app/BibleStoryCore/Sources app/BibleStoryCore/Tests && git commit -m "feat(app): P2 AccountModel with store persistence"
```

---

### Task 5: App-target services — Sign in with Apple, StoreKit 2, Keychain

**Files:**
- Create: `app/BibleStory/BibleStory/SignInWithAppleService.swift`
- Create: `app/BibleStory/BibleStory/StoreKitSubscriptionService.swift`
- Create: `app/BibleStory/BibleStory/KeychainAccountStore.swift`
- Create: `app/BibleStory/BibleStory/BibleStory.storekit`
- Modify: `app/BibleStory/project.yml` (Sign in with Apple capability; StoreKit config)

**Interfaces:**
- Consumes: `AuthenticationService`, `SubscriptionService`, `AccountStore`, `ParentAccount`.
- Produces: concrete implementations wired at the app composition root.

- [ ] **Step 1: Implement the Keychain account store**

Create `app/BibleStory/BibleStory/KeychainAccountStore.swift`:
```swift
import Foundation
import Security
import BibleStoryCore

/// Persists the ParentAccount as JSON in the Keychain (survives reinstalls,
/// keeps the small account record private on-device).
struct KeychainAccountStore: AccountStore {
    private let service = "com.biblestory.account"
    private let key = "parentAccount"

    func load() async -> ParentAccount? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return try? JSONDecoder().decode(ParentAccount.self, from: data)
    }

    func save(_ account: ParentAccount) async {
        guard let data = try? JSONEncoder().encode(account) else { return }
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }
}
```

- [ ] **Step 2: Implement Sign in with Apple**

Create `app/BibleStory/BibleStory/SignInWithAppleService.swift`:
```swift
import Foundation
import AuthenticationServices
import BibleStoryCore

/// Sign in with Apple, returning the stable user identifier.
@MainActor
final class SignInWithAppleService: NSObject, AuthenticationService, ASAuthorizationControllerDelegate {
    private var continuation: CheckedContinuation<String, Error>?
    struct Failed: Error {}

    func signInWithApple() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation?.resume(returning: credential.user)
        } else {
            continuation?.resume(throwing: Failed())
        }
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
```

- [ ] **Step 3: Add a StoreKit config with one subscription**

Create `app/BibleStory/BibleStory/BibleStory.storekit` (Xcode also edits this via its StoreKit editor; this seed is enough to build/test locally):
```json
{
  "identifier": "BibleStoryConfig",
  "products": [],
  "subscriptionGroups": [
    {
      "id": "family_plan",
      "localizations": [],
      "name": "Family Plan",
      "subscriptions": [
        {
          "displayPrice": "6.99",
          "familyShareable": true,
          "groupNumber": 1,
          "internalID": "monthly",
          "introductoryOffer": {
            "internalID": "trial7",
            "paymentMode": "free",
            "subscriptionPeriod": "P1W"
          },
          "productID": "com.biblestory.sub.monthly",
          "recurringSubscriptionPeriod": "P1M",
          "referenceName": "Monthly",
          "type": "RecurringSubscription"
        }
      ]
    }
  ]
}
```

- [ ] **Step 4: Implement the StoreKit 2 subscription service**

Create `app/BibleStory/BibleStory/StoreKitSubscriptionService.swift`:
```swift
import Foundation
import StoreKit
import BibleStoryCore

/// StoreKit 2 wrapper. Maps entitlement state to `SubscriptionStatus`.
struct StoreKitSubscriptionService: SubscriptionService {
    private let productID = "com.biblestory.sub.monthly"
    struct NoProduct: Error {}

    func currentStatus() async -> SubscriptionStatus {
        for await result in Transaction.currentEntitlements {
            if case .verified(let txn) = result, txn.productID == productID {
                if let exp = txn.expirationDate, exp < Date() { return .expired }
                return txn.offerType == .introductory ? .trial : .active
            }
        }
        return .none
    }

    func startFreeTrial() async throws {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else { throw NoProduct() }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            if case .verified(let txn) = verification { await txn.finish() }
        case .userCancelled, .pending:
            throw NoProduct()
        @unknown default:
            throw NoProduct()
        }
    }

    func restore() async throws -> SubscriptionStatus {
        try await AppStore.sync()
        return await currentStatus()
    }
}
```

- [ ] **Step 5: Enable capability + StoreKit config in the project**

In `app/BibleStory/project.yml`, add to the `BibleStory` target:
```yaml
    entitlements:
      path: BibleStory/BibleStory.entitlements
      properties:
        com.apple.developer.applesignin: [Default]
    scheme:
      testTargets: []
      storeKitConfiguration: BibleStory/BibleStory.storekit
```
Then regenerate:
```bash
cd /Users/graceyan/Desktop/alpha/bible-slm/app/BibleStory && xcodegen generate
```
Expected: `Created project at .../BibleStory.xcodeproj`.

- [ ] **Step 6: Build for the simulator**

Run (from `app/BibleStory/`):
```bash
xcodebuild -project BibleStory.xcodeproj -scheme BibleStory \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`. (`CODE_SIGNING_ALLOWED=NO` because the Sign in with Apple entitlement isn't validated on the simulator.)

- [ ] **Step 7: Commit**

```bash
git add app/BibleStory && git commit -m "feat(app): P2 Sign in with Apple, StoreKit 2, Keychain services"
```

---

### Task 6: Onboarding wizard UI + app wiring

**Files:**
- Create: `app/BibleStory/BibleStory/OnboardingView.swift`
- Modify: `app/BibleStory/BibleStory/BibleStoryApp.swift` (choose onboarding vs child zone at launch)

**Interfaces:**
- Consumes: `OnboardingModel`, `AccountModel`, `AppModel`, the three services (Task 5).
- Produces: the wizard UI + a root that shows onboarding when there's no account.

- [ ] **Step 1: Implement the wizard view**

Create `app/BibleStory/BibleStory/OnboardingView.swift`:
```swift
import SwiftUI
import BibleStoryCore

/// The first-run wizard. One screen per OnboardingStep. Calls `onFinished`
/// with the built account when the parent reaches the hand-off.
struct OnboardingView: View {
    @State var model: OnboardingModel
    let onFinished: (ParentAccount) -> Void

    var body: some View {
        VStack(spacing: 28) {
            switch model.step {
            case .welcome:
                promise("It never makes up Bible verses.")
                promise("It hands the hard questions back to you.")
                promise("It runs privately on your device.")
                primary("Get Started") { model.advance() }

            case .signIn:
                Text("Sign in to set up your family").font(.title2)
                primary("Sign in with Apple") { Task { await model.signIn() } }

            case .childProfile:
                Text("Who is this for?").font(.title2)
                TextField("Child's first name", text: $model.childName).textFieldStyle(.roundedBorder)
                Stepper("Age: \(model.childAge)", value: $model.childAge, in: 4...12)
                primary("Continue") { model.advance() }.disabled(!model.canAdvance)

            case .translation:
                Text("Choose your family's Bible").font(.title2)
                Picker("Translation", selection: $model.translation) {
                    ForEach(BibleTranslation.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }.pickerStyle(.wheel)
                primary("Continue") { model.advance() }

            case .safetySetup:
                Text("Safety is on by default").font(.title2)
                Text("You can fine-tune stories, topics, and time limits later in the Parent area.")
                    .multilineTextAlignment(.center).padding()
                primary("Continue") { model.advance() }

            case .paywall:
                Text("Start your free trial").font(.title2)
                Text("Then $6.99/month. Cancel anytime. No ads, ever.")
                primary("Start Free Trial") { Task { await model.startTrial() } }

            case .parentGateSetup:
                Text("Set up the grown-up lock").font(.title2)
                Text("We'll use Face ID or your passcode to keep the Parent area for grown-ups.")
                    .multilineTextAlignment(.center).padding()
                primary("Continue") { model.advance() }

            case .handoff:
                Text("All set! Pass the phone to your child.").font(.title2)
                primary("Start") {
                    if let account = model.makeAccount() { onFinished(account) }
                }

            case .done:
                ProgressView()
            }
        }
        .padding()
    }

    private func promise(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.seal.fill").font(.headline)
    }
    private func primary(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action).buttonStyle(.borderedProminent).controlSize(.large)
    }
}
```

- [ ] **Step 2: Wire onboarding vs child zone at launch**

Replace `app/BibleStory/BibleStory/BibleStoryApp.swift`:
```swift
import SwiftUI
import BibleStoryCore

@main
struct BibleStoryApp: App {
    @State private var appModel = AppModel(gate: BiometricParentGate())
    @State private var accountModel = AccountModel(store: KeychainAccountStore())
    @State private var loaded = false

    private let auth = SignInWithAppleService()
    private let subscriptions = StoreKitSubscriptionService()

    var body: some Scene {
        WindowGroup {
            Group {
                if !loaded {
                    ProgressView().task {
                        await accountModel.load()
                        loaded = true
                    }
                } else if accountModel.account == nil {
                    OnboardingView(
                        model: OnboardingModel(auth: auth, subscriptions: subscriptions)
                    ) { account in
                        Task { await accountModel.establish(account) }
                    }
                } else {
                    RootView(appModel: appModel)
                }
            }
        }
    }
}
```

- [ ] **Step 3: Regenerate and build**

Run (from `app/BibleStory/`):
```bash
xcodegen generate && xcodebuild -project BibleStory.xcodeproj -scheme BibleStory \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO build 2>&1 | tail -3
```
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Manual run verification**

Launch on the Simulator (first run, no account):
1. Welcome shows the three promises → Get Started.
2. Sign in with Apple sheet appears; complete it → advances to child profile.
3. Enter a name (Continue stays disabled until non-empty) + age → Continue.
4. Pick a translation → Continue → safety → Start Free Trial (StoreKit test sheet) → parent-gate → hand-off → Start.
5. App drops into the child zone (P1 "Story Library"). Relaunch → skips onboarding (account persisted in Keychain).

- [ ] **Step 5: Commit**

```bash
git add app/BibleStory && git commit -m "feat(app): P2 onboarding wizard UI + first-run routing"
```

---

## Self-Review

**Spec coverage (PRD §4 Epic A, §5.1, §6.4, §10, §12):**
- Sign in with Apple → Tasks 2, 5. Child profile → Tasks 2, 6. Translation choice → Tasks 2, 4, 6. Safety-setup step → Task 6 (detailed controls live in P6). Free-trial paywall → Tasks 2, 5, 6. Parent-gate setup + hand-off → Task 6 (uses P1's `BiometricParentGate`). Persistence/skip-on-relaunch → Tasks 4, 6. ✅

**Placeholder scan:** every code/test step is complete; commands show expected output. No TBD/TODO. ✅

**Type consistency:** `BibleTranslation`, `ChildProfile`, `SubscriptionStatus`, `ParentAccount`, `OnboardingStep`, `AuthenticationService`, `SubscriptionService`, `AccountStore`, `OnboardingModel`, `AccountModel` match the shared-interfaces contract. `AccountModel.establish` is P2-internal (not in the contract's representative member list) and used only within P2. ✅

**Noted deviations:**
1. Added `AccountModel.establish(_:)` (contract listed representative members `addChild`/`setTranslation`) to seed the account after onboarding — P2-internal, additive.
2. Simulator builds pass `CODE_SIGNING_ALLOWED=NO` because the Sign in with Apple entitlement isn't validated on the simulator.
3. Price ($6.99/mo) and trial length (1 week) are placeholders in the `.storekit` seed per PRD §12 Open Question Q3 — adjust when finalized.
