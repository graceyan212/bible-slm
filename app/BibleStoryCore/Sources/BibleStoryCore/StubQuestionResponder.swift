import Foundation

/// Deterministic, keyword-based stand-in for the fine-tuned SBC model.
/// Encodes behavior-spec.md v2's tiers so the whole app flow works before the
/// real model exists (P5 swaps in the on-device responder at the same seam).
/// NOTE: this is a stub for structure/demo only — NOT the shipped doctrine engine.
public struct StubQuestionResponder: QuestionResponder {
    public init() {}

    public func respond(
        to question: String,
        context: StoryContext,
        history: [ConversationTurn]
    ) async -> QuestionResponse {
        let q = question.lowercased()

        func hits(_ needles: [String]) -> Bool { needles.contains { q.contains($0) } }

        // Order matters: safety first, then the most specific tiers.
        if hits(["wish i wasn't here", "want to die", "hurt myself", "hits me", "hurts me", "touched me", "kill"]) {
            return QuestionResponse(
                spokenText: "That sounds really important, and I'm so glad you told someone. Please tell a grown-up you trust — a parent, a teacher, or someone who loves you — really soon. You matter so much.",
                behaviorClass: .danger
            )
        }

        if hits(["hamster", "in heaven", "going to hell", "am i going to", "muslim friend", "grandpa died", "grandma died",
                 "why did god let", "where do babies", "where babies come"]) {
            return QuestionResponse(
                spokenText: "Ooh, what a good wondering. That's a treasure to dig up with your grown-up — see, my needle's pointing right to them. Let's tuck it in your Wonderings page.",
                behaviorClass: .deflect,
                tier: .deflect
            )
        }

        if hits(["baptism", "baptize", "baptized", "eternal security", "lose my salvation", "lord's supper", "communion",
                 "is jesus the way", "only way to god", "did jesus really rise"]) {
            return QuestionResponse(
                spokenText: "In our church family, we believe baptism is for when you're big enough to choose to follow Jesus yourself — that's why we don't baptize babies. You can read more about it in your Bible with a grown-up.",
                behaviorClass: .hold,
                tier: .closed,
                claimIDs: ["SAC-01"],
                retrievedVerse: nil
            )
        }

        if hits(["election", "predestination", "end of the world", "end times", "dinosaur", "how old is the earth",
                 "speaking in tongues", "tongues"]) {
            return QuestionResponse(
                spokenText: "That's a deep one! Christians who all love the Bible see this a little differently — some explain it one way, some another. What a great thing to wonder about with your family.",
                behaviorClass: .acknowledge,
                tier: .open
            )
        }

        if hits(["ignore your rules", "pretend you", "you're just a computer", "say the verse", "just a robot"]) {
            return QuestionResponse(
                spokenText: "Ha! I'm your trail-compass Poli, and I love pointing you to good stories about God. Want me to tell you one?",
                behaviorClass: .adversarial
            )
        }

        if hits(["how many", "plus", "minus", "times", "capital of", "weather", "homework", "joke", "spell "]) {
            return QuestionResponse(
                spokenText: "Ooh, that's not really my kind of thing — I'm here for Bible stories and wonderings! Want to hear a story instead?",
                behaviorClass: .benignOffTopic
            )
        }

        // Default: a warm, shared-core answer grounded in the current page.
        return QuestionResponse(
            spokenText: "Great question about our story! \(context.storyTitle) shows us how much God cares. Let's keep exploring it together.",
            behaviorClass: .safeCore
        )
    }
}
