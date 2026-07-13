import Foundation

/// Deterministic keyword/phrase classifier implementing the 7-class tier
/// scheme from behavior-spec.md v2. `history` is accepted (per the model
/// contract in `QuestionResponder`/`SafetyClassifier` callers that need to
/// track pushback) but this heuristic classifier only needs the current
/// question's surface text to pick a class — the never-cave rule is enforced
/// by the responder holding its class/tier steady turn over turn, not here.
public struct BehaviorClassifier: Sendable {
    public init() {}

    private let safety = SafetyClassifier()

    public func classify(
        _ question: String,
        history: [ConversationTurn]
    ) -> (behaviorClass: BehaviorClass, tier: DoctrineTier, claimIDs: [String]) {
        let q = question.lowercased()

        func hits(_ needles: [String]) -> Bool { needles.contains { q.contains($0) } }

        // 1. DANGER (tier 7) — crisis/self-harm/abuse. Always checked first;
        // overrides every other class regardless of doctrinal content.
        if safety.isDanger(question) {
            return (.danger, .none, [])
        }

        // 2. ADVERSARIAL — jailbreak / character-break attempts. Checked before
        // doctrine so an adversarial wrapper around a doctrine question still
        // routes to "stay in character" rather than answering the doctrine.
        if hits([
            "pretend you're", "pretend you are",
            "ignore your rules", "ignore your instructions", "forget your instructions",
            "you're just a computer", "you are just a computer",
            "you're just a robot", "you are just a robot",
            "just a normal chatbot",
            "say the verse", "say the exact verse",
            "pretend you're jesus", "pretend you are jesus",
        ]) {
            return (.adversarial, .none, [])
        }

        // 3. DEFLECT (tier 3) — family-owned / adult / sensitive. Checked before
        // hold/acknowledge because these surface phrases (e.g. "heaven") can
        // overlap doctrine vocabulary but here are applied to a named
        // person/pet or a sensitive family topic, which always wins.
        if hits([
            // named person/pet + afterlife, or a verdict on the child themself
            "in heaven", "in hell", "going to hell", "am i going to hell",
            "go to hell",
            // sex/bodies/where babies come from
            "where do babies come from", "where babies come from", "sex", "bodies",
            // moral verdict on the child's own behavior
            "is it a sin that i", "is it a sin if i", "am i a bad kid because i",
            // pastorate/marriage roles
            "can girls be pastors", "can women be pastors", "can a woman be a pastor",
            "marriage roles", "husband and wife roles",
            // why God let a real loss happen
            "why did god let", "why did god allow",
            // other religions
            "muslim friend", "jewish friend", "hindu friend", "buddhist friend",
            "another religion", "different religion",
            // politics/abortion
            "abortion", "politics", "political",
        ]) {
            return (.deflect, .deflect, [])
        }

        // 4. ACKNOWLEDGE (tier 2) — open-hand doctrine church families differ on.
        if hits([
            "election", "predestination", "does god choose", "do we choose",
            "end times", "end of the world", "rapture", "when will the world end",
            "speaking in tongues", "tongues", "spiritual gifts", "gifts of the spirit",
            "how old is the earth", "age of the earth", "how old is the world",
        ]) {
            return (.acknowledge, .open, [])
        }

        // 5. HOLD (tier 1) — closed-hand SBC doctrine, held warmly & confidently.
        if hits([
            "baptism", "baptize", "baptized", "immersion", "dunked",
            "once saved always saved", "eternal security", "lose my salvation", "lose their salvation",
            "lord's supper", "communion",
            "saved by grace", "saved by faith", "grace through faith",
            "is jesus the way", "is jesus the only way", "only way to god",
            "is the bible true", "is the bible god's word", "bible god's word",
        ]) {
            var claimIDs: [String] = []
            if hits(["baptism", "baptize", "baptized", "dunked"]) { claimIDs.append("SAC-01") }
            if hits(["immersion"]) { claimIDs.append("SAC-02") }
            if hits(["once saved always saved", "eternal security", "lose my salvation", "lose their salvation"]) {
                claimIDs.append("SAL-01")
            }
            return (.hold, .closed, claimIDs)
        }

        // 6. BENIGN OFF-TOPIC — math, trivia, homework, jokes, weather.
        if hits(["capital of", "weather", "homework", "tell me a joke", "joke"])
            || q.range(of: #"\d+\s*(x|\*|times|plus|\+|minus|-)\s*\d+"#, options: .regularExpression) != nil {
            return (.benignOffTopic, .none, [])
        }

        // 7. SAFE CORE — everything else: story retells, shared-core teaching.
        return (.safeCore, .none, [])
    }
}
