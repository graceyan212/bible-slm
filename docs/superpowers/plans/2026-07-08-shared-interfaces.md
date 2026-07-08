# Shared Interfaces & Conventions (P2–P7)

> The cross-plan contract. Every plan (P2–P7) MUST use these exact type names, signatures, and conventions so the subsystems compose. If a plan needs to change one of these, update it here first.

## Conventions (established by P1)

- **Testable logic** lives in the `BibleStoryCore` Swift package (`app/BibleStoryCore/Sources/BibleStoryCore/`), unit-tested via `swift test --package-path app/BibleStoryCore`.
- **Apple-framework glue** (SwiftUI views, Sign in with Apple, StoreKit 2, Speech, AVFoundation, CloudKit, APNs, LocalAuthentication, on-device LLM runtime) lives in the `BibleStory` app target (`app/BibleStory/BibleStory/`), verified by `xcodebuild` build + manual Simulator run. Regenerate the project with `xcodegen generate` (from `app/BibleStory/`) after adding files; `project.yml` is the source of truth.
- **View-facing state**: `@MainActor @Observable public final class …Model`. **External dependencies**: a `public protocol` (like P1's `ParentGate`) so the core is testable with mocks; the concrete Apple-framework implementation lives in the app target.
- **Language/platform**: Swift 6 language mode, iOS 17+, `swift-tools-version: 6.0`.
- **TDD**: every core-package task is red→green→commit with complete test code. App-target glue tasks show complete code + a manual verification checklist.
- Existing P1 types: `Zone`, `ParentGate`, `AppModel` (with `zone`, `isAuthenticating`, `enterParentZone()`, `exitToChildZone()`).

## P2 — Accounts & onboarding

```swift
public enum BibleTranslation: String, CaseIterable, Sendable, Codable {
    case nirv, icb, esv, niv, kjv
    public var displayName: String { … } // "NIrV", "ICB", "ESV", "NIV", "KJV"
}

public struct ChildProfile: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var age: Int          // intended 7...9; out-of-band handled per PRD Q2
}

public enum SubscriptionStatus: Sendable, Equatable { case none, trial, active, expired }

public struct ParentAccount: Sendable, Codable, Equatable {
    public let appleUserID: String
    public var children: [ChildProfile]
    public var translation: BibleTranslation
    public var subscription: SubscriptionStatus
}

// The onboarding flow machine (drives the wizard).
public enum OnboardingStep: Sendable, Equatable {
    case welcome, signIn, childProfile, translation, safetySetup, paywall, parentGateSetup, handoff, done
}

// External dependencies (concrete impls in app target):
public protocol AuthenticationService: Sendable {
    func signInWithApple() async throws -> String   // returns stable appleUserID
}
public protocol SubscriptionService: Sendable {
    func currentStatus() async -> SubscriptionStatus
    func startFreeTrial() async throws
    func restore() async throws -> SubscriptionStatus
}
public protocol AccountStore: Sendable {            // persistence (Keychain/CloudKit in app target)
    func load() async -> ParentAccount?
    func save(_ account: ParentAccount) async
}

@MainActor @Observable public final class OnboardingModel { /* step, account draft, advance() */ }
@MainActor @Observable public final class AccountModel  { /* account, addChild(), setTranslation() */ }
```

## P3 — Story experience

```swift
public struct StoryPage: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public let imageName: String        // bundled illustration asset
    public let narrationText: String    // vetted, ~part of 400–700 word story
    public let audioAssetName: String   // pre-rendered premium-TTS narration asset
    public let isWonderPause: Bool      // invites the ask-a-question loop
}

public struct Story: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public let title: String
    public let coverImageName: String
    public let estimatedMinutes: Int
    public let pages: [StoryPage]
}

public protocol StoryLibrary: Sendable {            // loads bundled, vetted stories
    func allStories() -> [Story]
    func story(id: UUID) -> Story?
}
public protocol NarrationPlayer: Sendable {         // AVFoundation in app target
    func play(assetNamed name: String) async
    func pause() async
    func stop() async
}
public protocol StoryProgressStore: Sendable {      // persistence
    func markCompleted(storyID: UUID, childID: UUID) async
    func completedStoryIDs(childID: UUID) async -> Set<UUID>
}

@MainActor @Observable public final class StoryPlayerModel {
    // currentPageIndex, isPlaying, advance()/back()/replayPage(), atWonderPause, finished
}
@MainActor @Observable public final class LibraryModel { /* stories, completed markers */ }
```

## P4 — Ask-a-question loop (the SLM seam)

```swift
// Behavior-spec.md classes 1–6, named.
public enum ResponseClass: Int, Sendable, Equatable, Codable {
    case safeSharedCore = 1, redLine = 2, offTopic = 3, adversarial = 4, danger = 5, pushback = 6
}

// Read-only context the responder is given (never leaves device).
public struct StoryContext: Sendable, Equatable {
    public let storyID: UUID
    public let storyTitle: String
    public let pageIndex: Int
}

// What the responder returns — the app renders/speaks this.
public struct QuestionResponse: Sendable, Equatable {
    public let spokenText: String            // warm reply, in JSB register
    public let responseClass: ResponseClass
    public let retrievedVerse: String?       // ONLY ever from VerseProvider; never model-generated
    public let logToConversationGuide: Bool  // true for redLine/pushback
    public let isCrisis: Bool                // true for .danger → triggers P7
}

// THE seam. P4 ships a stub/mock; P5 provides OnDeviceModelResponder.
public protocol QuestionResponder: Sendable {
    func respond(to question: String, context: StoryContext) async -> QuestionResponse
}

// External deps (concrete impls in app target):
public protocol SpeechTranscriber: Sendable { func transcribe() async throws -> String } // Apple Speech
public protocol ReplyVoicer: Sendable { func speak(_ text: String) async }                // AVSpeech (on-device)
public protocol VerseProvider: Sendable {                                                  // retrieval only
    func verse(reference: String, translation: BibleTranslation) -> String?
}

// Produced by P4, consumed by P6.
public struct ConversationGuideEntry: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public let childID: UUID
    public let question: String
    public let discussionPrompt: String
    public let storyID: UUID
    public let createdAt: Date          // pass Date in from app layer; core stays deterministic
}

@MainActor @Observable public final class AskQuestionModel {
    // state: idle → listening → transcribing → thinking → presenting → done
    // startListening(), submit(question:), dismiss(); exposes current QuestionResponse
}
```

## P5 — On-device model integration

> **Runtime decision (P5):** use **llama.cpp** (GGUF, Metal), via the StanfordBDHG `llama` XCFramework, **not MLC-LLM** — MLC's static libs do not link on the iOS Simulator, which would break this project's simulator `xcodebuild build` gate. Core ML is the documented fallback path only.

```swift
public protocol LanguageModelEngine: Sendable {    // llama.cpp (GGUF/Metal) in app target
    func generate(prompt: String) async throws -> String
}

// Implements P4's QuestionResponder using the on-device model.
public struct OnDeviceModelResponder: QuestionResponder {
    public init(engine: LanguageModelEngine, verses: VerseProvider, translation: BibleTranslation)
    // respond(): build prompt (testable) → engine.generate() → parse/classify (testable)
    //            → enforce never-scripture guardrail → attach retrieved verse if referenced
}

// Testable, engine-free units:
public enum PromptBuilder { public static func prompt(question: String, context: StoryContext) -> String }
public enum ResponseParser {                          // model text → QuestionResponse fields
    public static func parse(_ raw: String) -> (text: String, cls: ResponseClass, verseRef: String?)
}
public enum ScriptureGuard {                          // strips/blocks any model-emitted verbatim verse
    public static func sanitize(_ text: String) -> String
}
```

## P6 — Parent dashboard

```swift
public struct SafetySettings: Sendable, Equatable, Codable {
    public var translation: BibleTranslation
    public var disabledStoryIDs: Set<UUID>
    public var disabledTopics: Set<String>
    public var sessionTimeLimitMinutes: Int?
    public var crisisAlertsEnabled: Bool
}
public struct ProgressSummary: Sendable, Equatable {
    public let childID: UUID
    public let completedCount: Int
    public let streakDays: Int
}
public protocol CloudSyncService: Sendable {          // CloudKit private DB in app target
    func fetchConversationEntries(childID: UUID) async throws -> [ConversationGuideEntry]
    func save(entry: ConversationGuideEntry) async throws
    func fetchSettings() async throws -> SafetySettings?
    func save(settings: SafetySettings) async throws
}

@MainActor @Observable public final class DashboardModel {
    // entries, settings, progress; loadGuide(), updateSettings(), filterByChild()
}
```

## P7 — Safety & crisis flow

```swift
public struct CrisisEvent: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public let childID: UUID
    public let createdAt: Date
    public let triggerSummary: String   // sanitized; never raw transcript beyond what's needed
}
public struct CrisisResource: Sendable, Equatable { public let label: String; public let contact: String }
public protocol CrisisAlertService: Sendable {        // APNs in app target
    func notifyParent(_ event: CrisisEvent) async
}
public enum CrisisResources { public static func forLocale(_ id: String) -> [CrisisResource] } // 988 US default

@MainActor @Observable public final class CrisisFlowModel {
    // present(reason:), fires CrisisAlertService, returnToCalm(); shows resources, never counsels
}
```

## Wiring map (who calls whom)

- `AppModel` (P1) owns zone routing. Onboarding (P2) runs before the child zone when no `ParentAccount` exists.
- Child zone: `LibraryModel` (P3) → `StoryPlayerModel` (P3). At an `isWonderPause` page, the child can open `AskQuestionModel` (P4).
- `AskQuestionModel` (P4) uses `SpeechTranscriber` → `QuestionResponder` → `ReplyVoicer`; on `logToConversationGuide` it creates a `ConversationGuideEntry`; on `isCrisis` it hands off to `CrisisFlowModel` (P7).
- `QuestionResponder` is `OnDeviceModelResponder` (P5) in production, a stub in P4's own tests.
- `DashboardModel` (P6, parent zone) reads `ConversationGuideEntry`s and `SafetySettings` via `CloudSyncService`; `CrisisFlowModel` (P7) writes `CrisisEvent`s the dashboard surfaces.
