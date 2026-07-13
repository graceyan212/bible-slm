import Foundation

/// Deterministic, high-recall detector for tier-7 "danger / crisis" input
/// (behavior-spec.md v2, row 7): self-harm and abuse disclosures.
///
/// This is a SAFETY gate, not a doctrine gate — false positives (flagging a
/// benign sentence) are acceptable and expected; false negatives are not.
/// Matching is case-insensitive substring/phrase matching over a curated,
/// commented phrase list. Keep additions here readable, not clever regex.
public struct SafetyClassifier: Sendable {
    public init() {}

    // MARK: - Self-harm / suicidal ideation phrases
    // Kid-register ways a 7-9 year old might express wanting to disappear,
    // die, or hurt themselves. Erring toward inclusion is intentional.
    private let selfHarmPhrases: [String] = [
        "wish i wasn't here",
        "wish i weren't here",
        "wish i was never born",
        "wish i wasn't born",
        "want to die",
        "wanted to die",
        "want to disappear forever",
        "hurt myself",
        "hurting myself",
        "kill myself",
        "killing myself",
        "no reason to live",
        "don't want to live",
        "do not want to live",
        "better off dead",
        "end my life",
    ]

    // MARK: - Abuse disclosure phrases
    // Kid-register ways a child might disclose being hurt or unsafe at home
    // or by another person. Deliberately broad — "hits me" / "hurts me" /
    // "scared to go home" alone are enough to flag.
    private let abusePhrases: [String] = [
        "my dad hits me",
        "my mom hits me",
        "my mum hits me",
        "my dad hurts me",
        "my mom hurts me",
        "my mum hurts me",
        "someone touches me",
        "someone touched me",
        "touches me",
        "touched me",
        "hits me",
        "hurts me",
        "scared to go home",
        "afraid to go home",
        "scared of my dad",
        "scared of my mom",
        "no one feeds me",
        "locks me in",
    ]

    /// True if `question` contains any curated crisis phrase (case-insensitive).
    /// High-recall by design: prefer a false positive over a missed disclosure.
    public func isDanger(_ question: String) -> Bool {
        let q = question.lowercased()
        return (selfHarmPhrases + abusePhrases).contains { q.contains($0) }
    }
}
