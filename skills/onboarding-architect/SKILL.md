---
name: onboarding-architect
description: Use when designing or auditing app onboarding, paywall, or activation flows — e.g. "design onboarding for my app", "what questions should signup ask", "how do I frame my paywall", "audit this onboarding/paywall". Generates a screen-by-screen flow spec (what to ask, how to sequence and word it, how to build the emotional arc, how to structure the paywall) grounded in studied onboarding/paywall principles, or audits an existing flow against them. Neutral menu with warnings — surfaces every lever and labels manipulative ones with their risk; never refuses.
---

# Onboarding Architect

Design (and audit) app onboarding + paywall flows. The output is a written, screen-by-screen
**flow spec** — text, no mockups. General-purpose: works for any app; adapt to the app in front of you.

## Core Principles (check every flow against these)

Every generated flow is checked against these; every audit evaluates against these. Each carries
named exemplars — reason from precedent, cite "like X does," don't assert in the abstract.

1. **Show, don't explain — let the user *do the real thing once* before the paywall.** A mini
   free-trial inside onboarding: finish a real lesson, generate one result, use the core feature.
   *(Duolingo, Elma.)* The strongest single lever.
2. **Engineer the emotional arc: problem → future-self → solution.** Make them feel the problem,
   frame who they become, position the app as the bridge. *(César's thesis.)*
3. **Collect data early — and make it visibly pay off in a personalized plan.** Every question
   feeds a named, personalized result so the paywall feels made-for-me. *(Speak, Byte Pal, Endless.)*
4. **The paywall is a flow, not a screen.** Sell the outcome first; multi-page; reduce risk with a
   "how your trial works" timeline + "cancel anytime."
5. **Pricing: annual-default, anchored, honest trial, "Most Popular" badge on the highest-LTV plan.**
   Two plans, annual pre-selected + badged, monthly as anchor. *(Honest line: badging annual with
   both prices visible is fine; hiding the cheap plan or badging a worse-value option is a dark pattern.)*
6. **Polish & memorability are table stakes.** Animation, delight, a nameable mascot. *(Bipul, Bump.)*
7. **Trust & momentum.** Social proof, founder/human touches, permission priming before the OS prompt,
   checklists for retention, review-ask at the emotional peak. *(Superhuman, One Year, Brilliant, Mural.)*

**Two philosophies override the pillars when they conflict:**
- **Length isn't the enemy — "feeling long" is.** Don't optimize for *short* (Duolingo ~60 screens).
  Optimize for delight/momentum so a long flow doesn't feel long.
- **Sometimes the best onboarding is none.** If the product speaks for itself (a tool where the first
  action *is* the value), recommend a minimal / no-onboarding path. Don't force a flow.

## Mode detection

- **Design** — user gives an app idea or asks "design onboarding / what should I ask / how do I frame the paywall." → run the Design procedure.
- **Audit** — user gives an existing flow (pasted screen sequence/copy, or screenshots). → run the Audit procedure.

If unclear, ask which they want.

## Design procedure

**Step 1 — Interview (~5 questions).** Ask these via the question tool before generating; they make
the flow bespoke. Ask them together or one at a time:
1. **The transformation** — who does the user *become*? (before → after)
2. **Buyer vs. user** — who pays, who uses, whom must onboarding persuade? (they can differ)
3. **Monetization model** — free trial / hard paywall / freemium / one-time; price point if known.
4. **Primary conversion goal** — trial start / paid / habit formation? (the north-star the flow optimizes)
5. **The one belief** — what must the user believe by the time they hit the paywall?

**Step 2 — Derive the strategy** (show briefly, ~3–4 lines): from the answers, name the *core desire*,
the *problem to make salient*, the *future-self frame*, and *what data is worth collecting* (each item
must earn its screen). Grounded in `references/emotional-arc.md`.

**Step 3 — Design the question set.** Use `references/question-taxonomy.md`. For each question give:
the wording, *why* it's there (personalize / problem-awareness / prime permission / feed pricing), and
how to present it. Apply the selection rule: include a question ONLY if its answer does one of those
jobs and visibly pays off later. Cut the rest.

**Step 4 — Sequence & frame the screens.** Use `references/onboarding-principles.md` +
`references/emotional-arc.md`. Typical arc: hook → value taste (do the real thing once) → questions →
"building your plan" delight → personalized plan reveal → trust beats → notification priming → paywall.
Adapt the order to the app; the invariant is *problem felt before plan offered, plan offered before price*.

**Step 5 — Design the paywall.** Use `references/paywall-levers.md`: model, two plans (annual default +
"Most Popular" badge, monthly anchor), trial + "how your trial works" timeline, framing levers. When a
manipulative lever is relevant (escalating exit discounts, urgency, toggles), you may surface it — but
label it with its risk from `references/dark-patterns.md` (neutral menu with warnings). Never silently
include a dark pattern; never refuse to discuss one.

**Step 6 — Emit the spec.** Fill in `templates/flow-spec.md`. Populate every section, including the
"Levers & risks" table (cite principle + source: César / Mobbin / Tim Gabe / etc.) and "What this flow
deliberately avoids." State any assumptions made where the interview was thin.

## Audit procedure

Input is an existing flow as **text** (pasted screens/copy) or **screenshots** (read them via vision).
1. Map each screen to the Core Principles it uses or misses.
2. Flag dark patterns using `references/dark-patterns.md`, each with its severity.
3. Note what's working (don't only criticize).
4. Give prioritized fixes (highest-leverage first), citing the principle each fix serves.
If screenshots are unreadable, name which screens you couldn't parse and audit the rest.

## Citation rule

Cite named exemplars from the references ("like Duolingo's first-lesson-before-signup"). Grep `corpus/`
only when you need a verbatim quote or a specific teardown detail. Always label single-app vendor stats
as directional A/B hypotheses, not laws — never promise a specific conversion lift.

## Edge cases

- **Vague app idea** → the interview resolves it; if answers are still thin, state assumptions explicitly and proceed.
- **Mold-breakers** (B2B/team tools, one-time purchase, ad-supported/no-paywall, hardware companions) →
  adapt. No-paywall → optimize the flow for *activation* (first real value + habit), not trial-start.
- **User skips interview questions** → use sensible defaults for that dimension, flagged in the spec's assumptions.
- **Product-speaks-for-itself** → per the overriding philosophy, recommend a minimal / no-onboarding path rather than forcing screens.
