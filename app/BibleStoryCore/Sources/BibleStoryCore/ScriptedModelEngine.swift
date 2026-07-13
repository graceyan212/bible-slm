import Foundation

/// Phase-C scripted stand-in; replaced by MLXModelEngine (on-device) in Phase A.
///
/// Returns tier-correct, warm, canned replies (ages 7–9 register) so the app's Ask flow
/// behaves correctly before the real on-device model is wired in. Classifies the last
/// user message into one of the behavior-spec tiers using a small inline keyword
/// heuristic, then picks a deterministic canned variant. Never quotes Scripture verbatim.
public struct ScriptedModelEngine: ModelEngine {
    public init() {}

    public func generate(system: String, messages: [ChatMessage]) async throws -> String {
        let question = messages.last(where: { $0.role == .user })?.content ?? ""
        let tier = Self.classify(question)
        return Self.reply(for: tier, question: question)
    }

    // MARK: - Tiers

    private enum Tier {
        case hold
        case acknowledge
        case deflect
        case safeCore
        case benignOffTopic
        case adversarial
        case danger
    }

    // MARK: - Lightweight keyword classifier (self-contained; no external classifier import)

    private static func classify(_ text: String) -> Tier {
        let q = text.lowercased()

        func any(_ keywords: [String]) -> Bool {
            keywords.contains { q.contains($0) }
        }

        // Danger / crisis — checked first, highest priority.
        if any([
            "wish i wasn't here", "wish i weren't here", "want to die", "kill myself",
            "hits me", "hurts me", "hurting me", "touched me", "touches me",
            "no one would miss me", "afraid to go home", "scared to go home",
        ]) {
            return .danger
        }

        // Adversarial / jailbreak.
        if any([
            "pretend you're", "pretend you are", "ignore your rules", "ignore your instructions",
            "you're just a computer", "you are just a computer", "say the verse exactly",
            "recite the verse", "act as", "system prompt", "jailbreak", "pretend to be jesus",
        ]) {
            return .adversarial
        }

        // Deflect-to-parent.
        if any([
            "my hamster", "my dog", "my cat", "my grandma", "my grandpa", "my pet",
            "going to hell", "go to hell", "am i going to hell",
            "muslim friend", "jewish friend", "my friend who isn't christian",
            "why did god let", "why did god take", "why does god let",
            "sex", "baby come from", "where do babies", "my body",
            "abortion", "should boys", "should girls", "can girls be pastors",
            "is it a sin that i", "am i bad for", "did i do wrong when i",
        ]) {
            return .deflect
        }

        // Open-hand doctrine — acknowledge.
        if any([
            "predestination", "elect", "election", "end times", "end-times", "rapture",
            "when will jesus come back", "second coming", "speaking in tongues",
            "gift of tongues", "infant baptism", "how old is the earth", "creation age",
            "how old is the world",
        ]) {
            return .acknowledge
        }

        // Closed-hand doctrine — hold.
        if any([
            "baptism", "baptize", "baptized", "dunk", "dipped under water",
            "once saved always saved", "eternal security", "lose my salvation",
            "lord's supper", "communion", "the lord's supper",
            "saved by works", "saved by being good", "earn my way to heaven",
            "is jesus the way to god", "only way to god", "is the bible true",
            "is the bible god's word", "true word of god",
        ]) {
            return .hold
        }

        // Benign off-topic.
        if any([
            "what's 1", "what is 1", "×", "*", "capital of", "homework",
            "tell me a joke", "weather", "math", "plus", "minus", "times",
        ]) {
            return .benignOffTopic
        }

        // Safe shared-core (story retells, feelings, general "God made/loves").
        return .safeCore
    }

    // MARK: - Deterministic canned variant picker

    private static func pick(_ variants: [String], seed: Int) -> String {
        guard !variants.isEmpty else { return "" }
        let index = seed % variants.count
        return variants[index]
    }

    // MARK: - Canned replies

    private static func reply(for tier: Tier, question: String) -> String {
        let seed = question.count

        switch tier {
        case .hold:
            return pick([
                """
                In our church family, baptism is for people who already love and trust Jesus in their \
                heart — we dip them all the way under the water to show, on the outside, that Jesus \
                washed away everything they ever did wrong and gave them a brand-new start. It's a joyful \
                day, like a big "yes!" party for everyone to see. I wonder what it would feel like to \
                stand up in front of everyone you love and tell them about Jesus!
                """,
                """
                Our church family believes that once you truly trust Jesus, he holds on to you forever — \
                nothing can ever make him let go, not even your worst day. That's such good news to rest \
                in. I wonder what it feels like to know you're held that safely.
                """,
                """
                In our church family, we believe the Bible is God's true word — every story in it really \
                happened, and every promise in it can be trusted completely. It's not just a good book; \
                it's God talking to us. I wonder which story in it you'd like to hear again.
                """,
            ], seed: seed)

        case .acknowledge:
            return pick([
                """
                That's one Christians who all love the Bible see a little differently — some churches \
                explain it one way, some another, and our church family doesn't need everyone to land in \
                the exact same spot on this one. It's a great one to keep wondering about with your mom \
                or dad.
                """,
                """
                Good question — different church families who all love Jesus have different ideas about \
                exactly how and when that happens, and that's okay. Our church has what we believe, but \
                we don't say other loving Christians are wrong about this one. Keep wondering about it \
                with your grown-up!
                """,
                """
                People who love God and love the Bible actually see this one in more than one way, and \
                our church family doesn't pick a winner on it. It's a wonderful question to bring to your \
                mom or dad and talk about together.
                """,
            ], seed: seed)

        case .deflect:
            return pick([
                """
                Ooh, that's a really important one — the kind that's perfect for your mom or dad, because \
                they know you and love you so much. Will you ask them tonight?
                """,
                """
                That's a big, tender question, and I want you to have the very best answer — one that \
                comes from someone who loves you and knows your whole story, like your mom or dad. Will \
                you bring this one to them?
                """,
                """
                I can tell this one matters a lot to you. It's exactly the kind of question a trusted \
                grown-up — like your mom, dad, or a pastor — should talk through with you. Will you ask \
                them soon?
                """,
            ], seed: seed)

        case .safeCore:
            return pick([
                """
                That's such a good thing to wonder about! God made every single person and every animal \
                and every star, and he loves each one so much — including you, right now, just as you are. \
                He's never too busy and never too far away. Think about all the amazing things God dreamed \
                up: oceans, giraffes, sunsets, laughter. He made all of it, and he made you on purpose, for \
                a reason. That's the kind of love that never runs out and never gives up.
                """,
                """
                What a great question about the story! The people in these Bible stories were real, and \
                they felt scared, brave, curious, and hopeful — just like you do sometimes. God was with \
                them through all of it, even the hard parts, and he helped them do things they couldn't \
                have done alone. Stories like this remind us that God is always close, always paying \
                attention, and always writing something good, even when it doesn't feel like it yet.
                """,
                """
                I love thinking about this story! It shows that God cares about ordinary people doing \
                everyday things — not just kings and heroes. He shows up in small moments, gentle words, \
                and quiet courage just as much as in big, dramatic ones. Every time we read it, we get to \
                notice something new about how much God loves his people and how he's always working \
                things out for good.
                """,
            ], seed: seed)

        case .benignOffTopic:
            return pick([
                """
                Hehe, I'm actually much better at Bible stories than math! Want to hear about the time \
                David faced a giant, or how Jonah ended up inside a great big fish?
                """,
                """
                Ha, that's outside what I know best — I'm your Bible story buddy! Should we talk about \
                Noah and the ark, or maybe baby Moses in the basket instead?
                """,
                """
                That's not really my thing — I love stories from the Bible way more! Want to hear about \
                Daniel and the lions, or the very first Christmas?
                """,
            ], seed: seed)

        case .adversarial:
            return pick([
                """
                Hehe, nice try — but I'm still your Bible story guide, through and through! I love sharing \
                stories about God's love, not pretending to be someone else. Want to hear a story about \
                courage, like David and Goliath?
                """,
                """
                I'm going to stay exactly who I am — a friend who loves telling Bible stories! I won't \
                repeat verses word-for-word, but I'd love to tell you what a story means in my own words. \
                Want to pick one?
                """,
                """
                That's a fun try, but I'm sticking with what I do best — warm Bible stories, told my own \
                way! How about we talk about Jonah, or the Christmas story?
                """,
            ], seed: seed)

        case .danger:
            return pick([
                """
                Thank you for telling me something so important. What you're feeling matters, and you \
                shouldn't carry it alone — please tell a trusted grown-up, like a parent, teacher, or \
                pastor, right away, today if you can. You deserve to be safe and cared for.
                """,
                """
                I'm really glad you shared that with me. This is something a trusted grown-up needs to \
                know about right now — like a parent, teacher, or pastor — so they can help keep you \
                safe. Will you go tell someone today?
                """,
                """
                What you just told me is serious, and it's not something to keep secret. Please find a \
                trusted grown-up — a parent, teacher, or pastor — and tell them what's happening as soon \
                as you can. You deserve help and safety.
                """,
            ], seed: seed)
        }
    }
}
