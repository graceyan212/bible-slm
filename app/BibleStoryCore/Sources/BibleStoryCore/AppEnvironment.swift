import Foundation
import Observation

/// Reader text size (a real accessibility control set from the parent dashboard).
public enum ReadingSize: String, CaseIterable, Sendable, Codable {
    case small, medium, large
    /// Multiplier applied to the reader's narrative + heading fonts.
    public var scale: Double {
        switch self {
        case .small:  0.9
        case .medium: 1.0
        case .large:  1.2
        }
    }
    public var label: String {
        switch self {
        case .small:  "Small"
        case .medium: "Medium"
        case .large:  "Large"
        }
    }
}

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

    /// Reading & accessibility (parent dashboard). Persisted; applied in the reader.
    public private(set) var readingSize: ReadingSize = .medium
    public private(set) var readAloud: Bool = false

    /// The model seam — `GuidedResponder` pipeline (scripted engine now, on-device MLX later).
    public let responder: QuestionResponder
    private let gate: ParentGate

    /// The parent's "Wonderings" — questions Poli deflected to the grown-up. On-device only.
    public let wonderings = WonderingsStore()

    /// On-device observability log for the beta (traces + 👍/👎). Export is consent-gated.
    public let traceStore = LocalTraceStore()
    /// Label for which engine produced a trace (updates when the on-device model goes live).
    public var modelVersion: String = "scripted"

    /// Sanitized danger/crisis events for the parent dashboard (on-device only).
    public let crisisEvents: CrisisEventStore
    /// Drives the danger/crisis screen (P7). ⚠️ SAFE placeholder wording — a licensed
    /// child-safety professional signs the copy + escalation before ship (docs/SAFETY-AND-COPPA.md).
    public let crisisFlow: CrisisFlowModel

    private let store = UserDefaults.standard
    private static let completedKey = "tn.completedStoryIDs"
    private static let translationKey = "tn.translation"
    private static let readingSizeKey = "tn.readingSize"
    private static let readAloudKey = "tn.readAloud"

    public init(responder: QuestionResponder,
                gate: ParentGate,
                crisisAlertService: CrisisAlertService = NoOpCrisisAlertService()) {
        self.responder = responder
        self.gate = gate
        let events = CrisisEventStore()
        self.crisisEvents = events
        self.crisisFlow = CrisisFlowModel(alertService: crisisAlertService, store: events)
        completedStoryIDs = Set(store.stringArray(forKey: Self.completedKey) ?? [])
        if let raw = store.string(forKey: Self.translationKey),
           let saved = BibleTranslation(rawValue: raw) { translation = saved }
        if let raw = store.string(forKey: Self.readingSizeKey),
           let size = ReadingSize(rawValue: raw) { readingSize = size }
        readAloud = store.bool(forKey: Self.readAloudKey)
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

    public func setReadingSize(_ s: ReadingSize) {
        readingSize = s
        store.set(s.rawValue, forKey: Self.readingSizeKey)
    }

    public func setReadAloud(_ on: Bool) {
        readAloud = on
        store.set(on, forKey: Self.readAloudKey)
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

    /// Run the biometric gate WITHOUT changing `phase`. Used when the parent area is a
    /// TAB inside the child home (so the bottom nav bar stays visible): the caller keeps
    /// the user in `.child` and simply switches the selected tab on success. Returns
    /// whether the grown-up authenticated. The `.parent` phase machinery is left intact
    /// for the legacy full-screen path.
    public func authenticateForParent() async -> Bool {
        guard !isAuthenticating else { return false }
        isAuthenticating = true
        defer { isAuthenticating = false }
        return await gate.authenticate()
    }

    /// Leaving the parent zone needs no gate.
    public func exitToChildZone() {
        if phase == .parent { phase = .child }
    }

    /// Build an ask-session bound to this environment's responder (one owner, shared seam).
    public func makeAskSession(context: StoryContext) -> AskSessionModel {
        let session = AskSessionModel(responder: responder, context: context,
                                      tracer: traceStore, modelVersion: modelVersion)
        session.onDeflect = { [weak self] question in
            self?.wonderings.log(question: question, storyTitle: context.storyTitle)
        }
        // Fire-toward-safety: a danger/crisis reply opens the crisis flow. We pass a FIXED
        // category reason (never the child's words) — privacy per docs/SAFETY-AND-COPPA.md.
        session.onCrisis = { [weak self] in
            guard let self else { return }
            let childID = self.activeChild?.id ?? UUID()
            Task {
                await self.crisisFlow.trigger(
                    childID: childID,
                    reason: "The child shared something that needs a caring grown-up."
                )
            }
        }
        return session
    }
}
