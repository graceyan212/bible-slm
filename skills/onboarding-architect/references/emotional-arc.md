# The emotional arc

Onboarding is not a tour of features. It is a short, engineered emotional journey that ends in a purchase decision the user experiences as *their own conclusion*, not a sales pitch. Every screen either advances the arc or wastes the user's patience — there is no neutral screen.

## The arc

The arc has six stages, always in this order:

1. **Problem-awareness** — surface a problem the user already has but hasn't fully named. Not "here's our product," but "here's a thing that's wrong with your life."
2. **Agitate** — make the problem concrete and a little uncomfortable. Quantify it, personify it, or show its trajectory if left unaddressed.
3. **Future-self / aspiration** — cut the discomfort with a vivid picture of the user on the other side of the problem. This is the emotional pivot from pain to hope.
4. **Personalized plan (the bridge)** — collect a small amount of data and turn it, visibly, into a plan built *for this specific user*. This is the bridge from "a problem exists" to "I have a way out, and it's mine."
5. **Proof / trust** — reduce the last bit of doubt: social proof, results, credibility markers, a review ask at the emotional peak.
6. **Earned paywall** — the offer arrives only after the user has felt the problem, seen the future self, and received something (the plan) that feels already theirs. Paying now feels like *completing* something rather than *starting* something.

This is César Alvarez's (@cesaralvarezll) thesis in spirit, drawn from his onboarding/paywall teardowns: make the user realize they have a problem, then position the app as the solution — and collect the data that personalizes the plan *early*, before the paywall, so the ask at the end feels tailored rather than generic. A paywall shown cold, with no arc behind it, is asking a stranger for money. A paywall shown after this arc is closing a deal with someone who has already told you what they want.

The order matters more than any individual beat. Skipping agitation and jumping straight to the plan produces a plan that feels arbitrary. Skipping the future-self and going straight from problem to plan produces something clinical, not aspirational. Putting proof before the personalized plan wastes your strongest trust signal on a user who doesn't yet have a stake in the outcome.

## Beat-by-beat

The canonical worked example is César's breakdown of Brainrot, built by indie developer Yoni Smolyar (@YoniSmolyar). Its onboarding sequence, screen by screen:

1. **Opens with a product demo** → 2. **Clearly shows the problem** → 3. **Collects user data early** → 4. **Explains how the app solves it** → 5. **Asks for a review mid-onboarding** → 6. **Paywall** (hard paywall, with a discount ladder on dismissal: close once for 50% off, close again for 80% off).

Mapped to the six-stage arc and given a job, a targeted emotion, and a copy pattern per screen:

| # | Screen | Arc stage | Job | Emotion targeted | Copy pattern |
|---|--------|-----------|-----|-------------------|---------------|
| 1 | **Product demo** | Problem-awareness (entry) | Show, don't tell, what the app does in under 10 seconds — establish competence before asking anything of the user | Curiosity, low-stakes interest | "Here's what this actually looks like." (video/animation, near-zero text) |
| 2 | **Show the problem** | Problem-awareness → Agitate | Name the user's problem in language they'd use themselves; make it feel personally diagnosed, not generic | Recognition, mild discomfort ("that's me") | "The more you [bad behavior], the more [bad outcome]." — a mirror, not a lecture |
| 3 | **Collect user data early** | Personalized plan (setup) | Ask a handful of low-friction questions that will visibly feed the plan shown next; each answered question is a small commitment | Investment, self-relevance | "Which of these feels most like you?" / tap-to-select, not open text |
| 4 | **Explain how the app solves it** | Future-self / aspiration + bridge to plan | Connect the data just given to a specific mechanism, using the user's own inputs as proof the app "gets" them | Hope, relief, "this was built for me" | "Because you picked [X], here's how [app] helps with that." |
| 5 | **Ask for a review mid-onboarding** | Proof / trust | Capture the rating request at the single highest point of emotional goodwill in the whole flow — before any friction (payment) is introduced | Pride, reciprocity, goodwill | "Loving it so far? A quick rating helps us keep building this." (native rating prompt, not App Store deep link) |
| 6 | **Paywall** | Earned paywall | Present the offer once the user has already invested data, attention, and (often) a public rating — asking now closes a loop instead of opening one | Ownership, momentum, mild loss-aversion on dismiss | Hard paywall; escalating dismiss-discount ("close again for 80% off") converts price-sensitive stragglers without discounting the first ask |

Other apps in the corpus follow the same skeleton with variations worth noting: language-learning and habit apps often run the interactive lesson *before* the questionnaire (letting the user feel the core value first), then build the "personalized plan" screen explicitly from the answers just given, then place the review ask directly before the paywall rather than mid-flow. The variation is in sequencing details (review right before vs. mid-flow; demo before vs. after data collection); the invariant is: **problem must be felt before the plan is offered, and the plan must be offered before the price is.**

## Psychological mechanisms

Each beat above is powered by a named mechanism, not intuition:

- **Goal-gradient effect** — motivation to complete a task increases as perceived distance to the goal shrinks. A visible progress bar or step counter ("3 of 6") during data collection makes each question feel like it's accelerating the user toward their plan, not delaying it. This is why data collection is broken into many small screens rather than one long form: more visible progress markers, more acceleration.

- **IKEA effect / effort-justification** — people assign more value to outcomes they had a hand in producing. Norton, Mochon & Ariely (2011, *Journal of Consumer Psychology*, "The IKEA effect: When labor leads to love") showed self-assembled items are valued more than identical pre-assembled ones. This is why the "personalized plan" screen must visibly derive from the answers just given (Beat 3 → Beat 4): a plan the user helped build by answering questions feels like *their* plan, not the app's product. The underlying cognitive mechanism traces back further to Aronson & Mills (1959), who showed that effort invested toward a goal increases the perceived value of that goal (studied via initiation severity and group liking) — the more a user "pays" in attention/data now, the more they value what it produces.

- **Loss-framing / future-self projection** — people weigh potential losses more heavily than equivalent gains (Kahneman & Tversky's prospect theory), and are more motivated by a vivid, concrete image of a specific future self than by an abstract feature list. The agitate beat (Beat 2) works by making inaction feel like an active loss ("the more you do X, the more Y degrades") rather than a neutral status quo; the aspiration beat (Beat 4) works by giving that loss a positive mirror image the user can project themselves into.

- **Reciprocity** — people feel obligated to return a favor. Giving the user something of real value for free and early (the demo in Beat 1, the personalized plan in Beat 4, or an interactive "try the core feature" moment before any ask) creates a small social debt that makes the later requests — a review, then a payment — feel like fair exchange rather than extraction.

- **Peak-end rule** — people judge an experience largely by its emotional peak and its ending, not its average (Kahneman et al.'s studies on retrospective evaluation of experienced utility). Placing the review ask (Beat 5) at the highest point of goodwill in the flow — right after the user has felt understood and been handed a plan, and before any friction or cost is introduced — maximizes the chance of a positive rating, because the rating is colored by the peak, not by whatever comes next.

**Note on question design:** the arc, not a checklist of "useful" questions, determines which questions belong in onboarding. A question earns its place only if it does one of two jobs: (a) sharpens the problem in Beat 2 (agitate) or (b) feeds a visibly personalized output in Beat 4 (the plan). Any question that does neither — however interesting the answer might be for analytics — is friction with no emotional payoff and should be cut or moved to post-onboarding. Use `references/question-taxonomy.md` to classify each candidate question and confirm it maps to one of these two jobs before including it.
