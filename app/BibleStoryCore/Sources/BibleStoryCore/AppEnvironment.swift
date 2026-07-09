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
    public private(set) var translation: BibleTranslation = .nirv
    public private(set) var isAuthenticating = false

    /// The model seam — `StubQuestionResponder` today, `OnDeviceModelResponder` (P5) later.
    public let responder: QuestionResponder
    private let gate: ParentGate

    public init(responder: QuestionResponder, gate: ParentGate) {
        self.responder = responder
        self.gate = gate
    }

    /// Finish first-run setup (parent account + kid onboarding) → enter the child zone.
    public func completeOnboarding(child: ChildProfile, translation: BibleTranslation) {
        self.activeChild = child
        self.translation = translation
        phase = .child
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
