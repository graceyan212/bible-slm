import Foundation
import Observation

/// The single composition root (the "front-door manager").
/// Owns the app phase, the active child profile, the chosen translation, and the
/// shared services — and constructs per-session models so every screen keys off
/// the SAME child + translation + service instances. (See ROADMAP P8.)
@MainActor
@Observable
public final class AppEnvironment {
    public enum Phase: Sendable, Equatable { case onboarding, child, parent }

    public private(set) var phase: Phase = .onboarding
    public private(set) var activeChild: ChildProfile?
    /// All explorer profiles on this account (parent can add / switch between them).
    public private(set) var children: [ChildProfile] = []
    public private(set) var translation: BibleTranslation = .nirv
    public private(set) var isAuthenticating = false

    /// Lessons the child has finished — the map/library unlock the NEXT stop once
    /// the current one is complete. Cumulative and persisted (grace, not guilt:
    /// progress is only ever gained, never lost).
    public private(set) var completedStoryIDs: Set<String> = []

    /// The model seam — `StubQuestionResponder` today, `OnDeviceModelResponder` (P5) later.
    public let responder: QuestionResponder
    private let gate: ParentGate

    private let store = UserDefaults.standard
    private static let completedKey = "tn.completedStoryIDs"
    private static let translationKey = "tn.translation"

    public init(responder: QuestionResponder, gate: ParentGate) {
        self.responder = responder
        self.gate = gate
        completedStoryIDs = Set(store.stringArray(forKey: Self.completedKey) ?? [])
        if let raw = store.string(forKey: Self.translationKey),
           let saved = BibleTranslation(rawValue: raw) { translation = saved }
    }

    /// Finish first-run setup (parent account + kid onboarding) → enter the child zone.
    public func completeOnboarding(child: ChildProfile, translation: BibleTranslation) {
        self.activeChild = child
        if !children.contains(where: { $0.id == child.id }) { children.append(child) }
        setTranslation(translation)
        phase = .child
    }

    // MARK: Lesson progression

    /// Mark a lesson finished (called from the reader's completion screen). Unlocks
    /// the next stop on the trail. Idempotent + persisted.
    public func markStoryComplete(_ id: String) {
        guard !completedStoryIDs.contains(id) else { return }
        completedStoryIDs.insert(id)
        store.set(Array(completedStoryIDs), forKey: Self.completedKey)
    }

    public func isStoryComplete(_ id: String) -> Bool { completedStoryIDs.contains(id) }

    // MARK: Parent-dashboard controls

    /// Change the family Bible translation (verse cards read from this). Persisted.
    public func setTranslation(_ t: BibleTranslation) {
        translation = t
        store.set(t.rawValue, forKey: Self.translationKey)
    }

    /// Add a new explorer profile (parent dashboard).
    public func addChild(_ child: ChildProfile) {
        if !children.contains(where: { $0.id == child.id }) { children.append(child) }
        if activeChild == nil { activeChild = child }
    }

    /// Switch the active explorer.
    public func selectChild(_ child: ChildProfile) {
        guard children.contains(where: { $0.id == child.id }) else { return }
        activeChild = child
    }

    /// Kid-mode lock: reaching the parent zone requires passing the gate.
    public func enterParentZone() async {
        guard phase == .child, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }
        if await gate.authenticate() {
            phase = .parent
        }
    }

    /// Leaving the parent zone needs no gate.
    public func exitToChildZone() {
        if phase == .parent { phase = .child }
    }

    /// Build an ask-session bound to this environment's responder (one owner, shared seam).
    public func makeAskSession(context: StoryContext) -> AskSessionModel {
        AskSessionModel(responder: responder, context: context)
    }
}
