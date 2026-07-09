import Foundation

/// Behavior classes the model produces — mirrors behavior-spec.md v2 and the
/// training schema's `behavior_class`. (Supersedes the old 6-class ResponseClass.)
public enum BehaviorClass: String, Sendable, Equatable, Codable {
    case hold            // closed-hand SBC doctrine — assert warmly, NEVER cave under pushback
    case acknowledge     // open-hand — note church families differ, do NOT adjudicate
    case deflect         // family-owned/adult/sensitive — hand to the parent (Wonderings)
    case safeCore        // shared-core teaching / story question — warm answer
    case benignOffTopic  // math/jokes/weather — warm redirect
    case adversarial     // jailbreak — stay in character
    case danger          // crisis — safety flow, never counsel
}

/// Doctrinal tier for hold/acknowledge/deflect (parity with data/bfm_claims.json); else `.none`.
public enum DoctrineTier: String, Sendable, Equatable, Codable {
    case closed, open, deflect, none
}

/// Read-only context the responder is given (never leaves device).
public struct StoryContext: Sendable, Equatable {
    public let storyID: UUID
    public let storyTitle: String
    public let pageIndex: Int
    public let pageNarration: String   // on-screen retelling text — grounds the answer

    public init(storyID: UUID, storyTitle: String, pageIndex: Int, pageNarration: String) {
        self.storyID = storyID
        self.storyTitle = storyTitle
        self.pageIndex = pageIndex
        self.pageNarration = pageNarration
    }
}

/// One prior turn in the current ask-session, so the responder can HOLD under repeated pushback.
public struct ConversationTurn: Sendable, Equatable {
    public let question: String
    public let reply: String

    public init(question: String, reply: String) {
        self.question = question
        self.reply = reply
    }
}

/// What the responder returns — the app renders/speaks this.
public struct QuestionResponse: Sendable, Equatable {
    public let spokenText: String
    public let behaviorClass: BehaviorClass
    public let tier: DoctrineTier
    public let claimIDs: [String]
    public let retrievedVerse: String?

    public init(
        spokenText: String,
        behaviorClass: BehaviorClass,
        tier: DoctrineTier = .none,
        claimIDs: [String] = [],
        retrievedVerse: String? = nil
    ) {
        self.spokenText = spokenText
        self.behaviorClass = behaviorClass
        self.tier = tier
        self.claimIDs = claimIDs
        self.retrievedVerse = retrievedVerse
    }

    /// DEFLECT questions are logged to the parent's Wonderings / Conversation Guide.
    public var logToConversationGuide: Bool { behaviorClass == .deflect }
    /// DANGER routes to the crisis flow (P7).
    public var isCrisis: Bool { behaviorClass == .danger }
}

/// THE seam. P4/skeleton ships a stub; P5 provides the on-device model responder.
/// `history` carries prior turns so HOLD survives pushback (behavior-spec v2).
public protocol QuestionResponder: Sendable {
    func respond(to question: String, context: StoryContext, history: [ConversationTurn]) async -> QuestionResponse
}
