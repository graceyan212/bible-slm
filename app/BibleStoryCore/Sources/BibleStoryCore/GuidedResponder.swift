import Foundation

/// The engine-agnostic pipeline that turns a raw `ModelEngine` into the app's
/// `QuestionResponder`. Composes the deterministic guards around generation:
///
///   a. SafetyClassifier — a danger/crisis input short-circuits to a safe reply and
///      the model is NEVER called (defense-in-depth; we don't trust the model for safety).
///   b. Build the shared SYSTEM_PROMPT + prior turns + the new question.
///   c. engine.generate(...) — the tuned model (or the Phase-C scripted stand-in).
///   d. VerseGuard — deterministically strip any verbatim Scripture / chapter:verse.
///   e. BehaviorClassifier — tag class/tier/claimIDs for routing (deflect → parent
///      "Wonderings" via `QuestionResponse.logToConversationGuide`).
///
/// The system prompt is passed UNCHANGED (train == serve); story context is accepted
/// but deliberately not injected into the prompt, since the model was trained without
/// it — keeping in-app behavior faithful to the offline eval.
public struct GuidedResponder: QuestionResponder {
    private let engine: ModelEngine
    private let systemPrompt: String
    private let safety = SafetyClassifier()
    private let classifier = BehaviorClassifier()
    private let verseGuard = VerseGuard()

    public init(engine: ModelEngine, systemPrompt: String = SystemPrompt.sbcKidsGuide) {
        self.engine = engine
        self.systemPrompt = systemPrompt
    }

    public func respond(to question: String,
                        context: StoryContext,
                        history: [ConversationTurn]) async -> QuestionResponse {
        // a. Safety first — never send a crisis to the model.
        if safety.isDanger(question) {
            return QuestionResponse(spokenText: Self.crisisReply,
                                    behaviorClass: .danger, tier: .none)
        }

        // b. Messages: prior turns (so HOLD survives pushback) + the new question.
        var messages: [ChatMessage] = []
        for turn in history {
            messages.append(ChatMessage(role: .user, content: turn.question))
            messages.append(ChatMessage(role: .assistant, content: turn.reply))
        }
        messages.append(ChatMessage(role: .user, content: question))

        // e. (computed regardless of engine outcome — drives logging/routing)
        let (cls, tier, ids) = classifier.classify(question, history: history)

        // c. Generate, with a warm fallback if the engine errors.
        let raw: String
        do {
            raw = try await engine.generate(system: systemPrompt, messages: messages)
        } catch {
            return QuestionResponse(spokenText: Self.fallbackReply,
                                    behaviorClass: cls, tier: tier, claimIDs: ids)
        }

        // d. Verse-guard, with a fallback if guarding leaves nothing usable.
        let cleaned = verseGuard.clean(raw).trimmingCharacters(in: .whitespacesAndNewlines)
        let spoken = cleaned.isEmpty ? Self.fallbackReply : cleaned

        return QuestionResponse(spokenText: spoken, behaviorClass: cls, tier: tier, claimIDs: ids)
    }

    /// Never counsels, never promises secrecy, never asks for details — routes to a
    /// trusted grown-up (the real product also fires its separate safety flow via `isCrisis`).
    static let crisisReply =
        "That sounds really important, and I want to make sure you're okay. Please tell a grown-up " +
        "you trust — like a parent, teacher, or someone who takes care of you — as soon as you can. " +
        "They'll want to help you."

    static let fallbackReply =
        "Ooh, that's a good one. Let's save it for your grown-up so you can wonder about it together."
}
