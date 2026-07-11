# Lamplight — Onboarding & Paywall Flow

*(Illustrative app name — a reverent, evangelical-parent-facing bedtime Bible app for 7–9-year-olds.
Interview answers were supplied directly; no additional questions asked.)*

## Strategy

**Core desire:** the parent wants to feel like a faithful, present spiritual leader for their
child — not through heroic effort or seminary-grade knowledge, but through a small, repeatable act
they can actually sustain. **Problem made salient:** bedtime devotion time either doesn't happen,
gets improvised badly ("uhh, let's just pray"), or turns into a battle to hold a 7–9-year-old's
attention — and every skipped night quietly reinforces the parent's fear that they're failing at
this part of parenting. **Future-self frame:** a parent who has a steady, low-effort 10-minute
nightly rhythm; a child who *asks* for story time instead of stalling bedtime; spiritual formation
happening reliably instead of sporadically, guilt-free. **The one belief the user must hold by the
paywall:** *this is doctrinally safe, reverent, and will actually help me — it will not try to
replace me as the parent.* Every trust beat in this flow exists to serve that one sentence, because
for this buyer the belief is the actual conversion lever — more than price, more than polish.

**What's worth collecting:** the child's name and age (personalizes story voice/reading level —
critical, since a 7-year-old and a 9-year-old need different complexity), the parent's current
devotional frequency (baseline + agitates the gap), the single biggest obstacle they face (feeds
both the agitate beat and the personalized-plan mechanism), church tradition/doctrinal alignment
(the segmentation question that *is* the trust question for this buyer), and bedtime/reminder time
(commitment + permission priming). Six questions total — each is load-bearing per the selection
rule in `references/question-taxonomy.md`; nothing generic ("how did you hear about us," a
marketing-analytics-only question) makes the cut, because this buyer has low tolerance for
anything that smells like a survey rather than a plan being built for their family.

## The question set

| Question | Why it's here | Wording | Presentation |
|---|---|---|---|
| Child's name | personalize — becomes the anchor for every later screen ("[Name]'s reading tonight...") | "What's your child's name?" | single free-text field, one screen |
| Child's age | personalize plan — sets reading level/theological complexity tier (7 vs. 9 differ a lot at this range) | "How old is [Name]?" — chips: 7 / 8 / 9 | single-select chips |
| Current devotional practice | agitate + baseline — establishes the gap the plan will close | "How often does Bible time happen at bedtime right now?" — Most nights / A few nights a week / Rarely / Never, but I want to start | single-select list, neutral non-shaming labels |
| Biggest obstacle | agitate the problem + feeds the plan's specific fix | "What usually gets in the way?" — I'm too tired to do it well / I don't know what to say or where to start / [Name] loses interest fast / I worry about getting the theology right | single-select list |
| Church background / doctrinal alignment | segmentation that doubles as the trust question for this buyer — feeds the "aligned with your tradition" reveal at the plan/trust screens | "Which best describes your family's church background?" — Southern Baptist / Baptist / Non-denominational evangelical / Other Christian tradition / Still figuring it out | single-select list |
| Bedtime / reminder time | commitment + primes the notification permission ask | "What time is bedtime at your house?" | time picker, immediately followed by a custom pre-permission screen |

*(Cut: "how did you hear about us" — no personalization or trust payoff for this buyer, pure
attribution; can move to post-onboarding analytics if needed. Cut: gender/name-of-parent — no
plan or content changes based on it.)*

## The flow (screen-by-screen)

1. **Welcome / hook** [parent]
   - Purpose: problem-awareness entry — establish the transformation on offer in one breath, low-text, no pitch yet.
   - Copy: headline "Ten quiet minutes. Every night. The Word, not just a story about it." · sub "A bedtime Bible time you can actually keep up." · CTA "Get started"
   - Levers: sell-the-outcome-not-the-features (Timehop's silent-demo instinct, applied as a single sentence instead of a feature list).

2. **Name the problem** [parent]
   - Purpose: problem-awareness → agitate. Mirror the parent's actual bedtime experience back to them.
   - Copy: headline "Most nights end in a rushed prayer — or nothing at all." · sub "Not because you don't care. Because no one handed you a plan." · CTA "Continue"
   - Levers: agitate beat (emotional-arc.md, Beat 2) — a mirror, not a lecture; named, specific, not generic guilt.

3. **Do the real thing once — tonight's story, right now** [parent + child]
   - Purpose: taste the actual core experience before any account, question, or payment ask — the single strongest lever in the whole flow. A complete, real 8–10 minute story (e.g., David and Goliath) plays/reads aloud in full, exactly as a paying family would get it, with the reverent narration tone and a short closing reflection question for the child.
   - Copy: headline "Try tonight's story right now — no sign-up." · sub "Read it together, or let us read it to you." · CTA "Begin tonight's story"
   - Levers: **do-the-real-thing-once** (Duolingo's real first lesson before account creation; Elma's try-before-account pattern) — this is `onboarding-principles.md`'s single most effective, most underused lever for exactly this reason: a devotional app's core value (a shared 10 minutes) is the hardest thing to fake with a screenshot or a demo video, so let them actually have the 10 minutes.

4. **After the story — name the stakes** [parent]
   - Purpose: agitate, now with earned credibility (they just experienced the thing). Quantify the trajectory, softly and honestly — no fabricated stat.
   - Copy: headline "That was one night. What about the other 364?" · sub "Families who keep a steady rhythm — even imperfectly — are the ones whose kids still want to talk about faith as teenagers." · CTA "Build our plan"
   - Levers: loss-framing / future-self projection (emotional-arc.md) — deliberately framed as a directional claim, not a manufactured statistic, per the citation rule (no vendor-style lift number invented for a claim this consequential).

5–10. **Six data-collection screens** [parent] — one question per screen (see table above), each with a visible step indicator ("2 of 6"), each phrased conversationally, not as a form field.
   - Purpose: personalize the plan (Beat 3/4 of the emotional arc) and prime the permission ask.
   - Copy pattern: "[Question]" with a one-line reason where the question is sensitive (age: "This helps us pick the right reading level for [Name]" — never asked with no stated reason, per `question-taxonomy.md`'s demographic-question rule).
   - Levers: goal-gradient effect (progress indicator accelerates completion); IKEA effect (answers will visibly build the plan next); Selection rule from `question-taxonomy.md` — every question here does at least one of personalize/agitate/prime-permission/segment.

11. **"Building [Name]'s plan..."** [parent]
    - Purpose: delight beat that also does real work — a brief animated moment (an oil lamp being lit, one flame per answer given) rather than a static spinner.
    - Copy: "Lighting the way for [Name]'s reading plan..."
    - Levers: delight-carries-length (Bipul/Bump-style animated wait states) — kept understated and warm rather than playful/cartoonish, to match the reverent tone this buyer expects (an explicit adaptation, not a default mascot-and-confetti treatment).

12. **Plan reveal** [parent]
    - Purpose: the bridge — show the answers just given, visibly turned into a plan that's theirs. This is the single highest-leverage personalization screen in the flow.
    - Copy: headline "[Name]'s Bedtime Plan" · body: "Because bedtime is often rushed, we start with 5-minute Quick Mode this week, building to the full 10 minutes by week two. Readings are leveled for age [Age] and aligned with [Church background] teaching. Reminder set for [Bedtime]." · CTA "See how it works"
    - Levers: personalized-plan-as-bridge (Speak's "in 2 months you'll..." pattern; Byte Pal's date-stamped plan) — every clause in the body maps back to one of the six answered questions, satisfying the "visibly pays off" requirement in `question-taxonomy.md`.

13. **Trust beats** [parent]
    - Purpose: proof/trust beat, placed after the plan (when the parent has a stake) and before the price (when doubt needs resolving). Directly targets "the one belief."
    - Copy: three stacked cards — (1) "Reviewed for doctrinal alignment with historic evangelical/Baptist teaching — never generates or improvises Scripture." (2) "Written by parents and pastors, read by real families." with 2–3 short, honest parent testimonials (no fabricated review counts or star ratings — see risk note below). (3) "This is a companion to your parenting, not a substitute for it — you're still the one doing this with [Name]." — stated explicitly, not implied, because it's the literal belief this whole flow is built to install.
    - Levers: human/founder-touch trust (One Year's handwritten-note instinct, adapted as an explicit non-replacement promise); social proof (Timely's dedicated proof page, kept modest and specific rather than inflated).

14. **Notification permission priming** [parent]
    - Purpose: prime the OS notification prompt with a custom screen tied to the commitment just made.
    - Copy: headline "We'll remind you at [Bedtime] — gently, once a night." · sub "So this becomes a rhythm, not one more thing to remember." · CTA "Turn on reminders" (native OS prompt follows)
    - Levers: permission-priming (Brilliant's "I'll remind you so it becomes a habit" pattern) — placed right after the commitment/effort question, per `question-taxonomy.md`'s stated mechanism.

15–18. **Paywall (multi-page)** [parent] — see full breakdown below.

## The paywall

- **Model:** Soft-leaning hybrid — the parent has already received the full free sample story and the personalized plan before any price is shown, and the flow explicitly avoids forcing a same-session hard close (per the stated conversion goal: trial-start is a considered purchase, not an impulse buy). The paywall is reachable, clearly presented, and easy to defer without punishing the parent for deferring.
- **Plans:** Annual $60/yr ("$5/mo," billed yearly) — **default-selected, "Most Popular" badge** · Monthly $9.99/mo (≈$120/yr) — shown as the anchor, both prices fully visible side by side · a Family plan (multiple children) tucked behind a quiet "See all plans" link, not hidden or deceptively surfaced.
- **Trial:** 7 days, full access, card required to start (chosen deliberately — see Levers & risks table) — **"how your trial works" timeline** shown directly on the paywall: *Today: full access, nothing charged → Day 5: reminder email/push that the trial is ending in 2 days → Day 7: card charged for the annual plan unless canceled.* Modeled directly on Blinkist's redesign, which reduced "I felt tricked" complaints while raising sign-ups.
- **Framing:** value framing ("Give [Name] a reading of Scripture almost every night this year" — the future being bought, not a feature list) · price anchoring (monthly-equivalent breakdown under the annual price: "$60/yr — less than $5/month") · honest social proof (specific, attributed parent quotes, no invented review counts) · a persistent "Cancel anytime, no questions asked" subtitle under the CTA.
- **CTA:** "Start my free 7-day trial" · secondary, non-confirmshaming: "Not ready yet — email me tonight's story instead" (this captures the parent as a lead and lets them leave with something of real value, rather than a guilt-worded decline like "No, I don't want to help my child grow spiritually" — which this flow explicitly does not use).

## Levers & risks table

| Choice | Principle | Source | Conversion note | Risk |
|---|---|---|---|---|
| Full free story before any account/question/paywall | do-the-real-thing-once | Mobbin (Duolingo, Elma) | strongest single lever in the corpus; especially rare/effective for a devotional product where value is hard to convey passively | none |
| Annual default + "Most Popular" badge, both prices visible | pricing architecture | Mobbin paywall study | anchors annual as the obvious choice without concealing monthly | none — see `paywall-levers.md`'s honest line: badging while both prices stay visible and reachable is not a dark pattern |
| Family plan hidden behind "See all plans" | reduce cognitive load on base paywall | Mobbin paywall study | keeps the base two-plan comparison simple | low — legitimate only because it's not the cheaper single-child option being hidden; still worth monitoring in testing |
| "How your trial works" timeline | reduce risk → reduce hesitation | Mobbin (Blinkist teardown) | directly reduces the "will I forget to cancel" objection that this trust-sensitive buyer will definitely have | none — this is now the Apple-compliant shape (2026 toggle ban), not just a growth tactic |
| Card required to start trial | friction-filters-for-intent | Mobbin (Outsider teardown) | can raise trial-to-paid conversion by filtering low-intent starts | **medium** — the cited 5× lift is explicitly flagged in `paywall-levers.md` as survivorship-biased/Day-35-measured; also adds real friction for a buyer this deal-conscious. Offered here as a real lever, not a default recommendation — a no-card trial is the lower-risk alternative and may suit this trust-first brand better; test both. |
| Explicit "not a substitute for you as the parent" statement | trust beat / the one belief | derived directly from interview answer #5 | this is the literal belief this flow is built to install — the single highest-leverage trust copy in the flow for this specific buyer | none |
| Single, one-time exit offer if paywall is dismissed (a short trial extension, not a discount) | recovery | Mobbin paywall study ("prefer longer trial over discount as recovery") | recovers some of the "not ready yet" traffic without training users to expect a discount | low — a one-time, non-repeating, non-discount offer; see avoided-patterns below for what this deliberately is *not* |

## What this flow deliberately avoids

- **Escalating exit-discount ladder (close → 50% off → close again → 80% off)** — offered here as a menu item, not silently omitted: it is a genuinely high-converting pattern documented across the corpus (Brainrot, others), but it (a) trains users to distrust the first price, (b) is explicitly called out by Mobbin's own paywall researcher as trust-eroding and increasingly recognized, and (c) is the exact "post-close offer stacked on the main paywall" pattern Apple began rejecting outright in 2026. For a brand whose entire conversion thesis is "trust me with your kid's discipleship," this is the wrong trade even before the App Store risk. **Not used.**
- **Fake urgency / countdown timers** — would directly contradict the "considered purchase, no forced same-session close" instruction, and reads as manipulative against a reverent brand promise. **Not used.**
- **Confirmshaming decline copy** ("No, I don't want my child to grow in faith") — the actual secondary CTA above ("email me tonight's story instead") was deliberately written to be a real, non-guilt-worded offer instead. **Not used.**
- **Free-trial toggle styled as a settings switch** — App-Store-non-compliant (Guideline 3.1.2) as of 2026 and ambiguates the commitment moment for a buyer this trust-sensitive. The trial CTA here is an explicit button with the charge date stated on the same screen. **Not used.**
- **Hidden cheap plan / misleading "Most Popular" badge on the worse-value plan** — both prices stay visible at the paywall; the badge sits on the plan that genuinely is the best per-period value. **Not used.**
- **Selling to or soliciting the child in-character** — the child is the end user of the *content* but is never the audience for any question, plan-reveal copy, or paywall screen; every onboarding and monetization screen above is marked [parent] or [parent + child], never [child] alone. This is a hard COPPA/FTC line (`dark-patterns.md`'s highest-severity entry, citing the Epic Games $275M settlement), not just a UX preference, and it also directly serves this app's own "not a substitute for the parent" promise. **Not used, by design constraint, not just by choice.**
- **Card-required trial** — offered above as a real, flagged lever (see table) rather than silently used or silently excluded; the honest tension (higher-intent conversion vs. added friction for a deal-conscious, trust-first buyer) is stated so the call can be made deliberately, with a no-card variant named as the lower-risk alternative to test against.
