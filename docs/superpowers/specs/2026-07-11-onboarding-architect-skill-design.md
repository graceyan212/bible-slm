# Design: `onboarding-architect` skill

**Date:** 2026-07-11
**Status:** Approved for planning

## Summary

An interview-driven, **general-purpose** Claude skill that **generates** (and can **audit**)
app onboarding + paywall flows from a distilled-but-cited knowledge base. The emotional arc
dictates which questions are necessary — data is never collected for its own sake; every
question exists to personalize, agitate the problem, or make the paywall feel earned.

Primary job: **generation** (from an app idea → a full flow spec). Audit is a lighter
secondary mode. Ethics stance: **neutral menu with warnings** — it surfaces every lever,
including aggressive ones, but labels manipulative patterns with their trust/App-Store/legal
risk and leaves the choice to the user.

## Core principles (always top of mind)

`SKILL.md` opens with these named pillars, and every generated flow is checked against
them (and every audit evaluates against them). They are evidence-ranked from the corpus —
César's frequency across 152 teardowns cross-referenced with Mobbin's conversion science.
Each pillar carries its named exemplars so the skill reasons from concrete precedent, not
abstraction.

1. **Show, don't explain — let the user *do the real thing once* before the paywall (a mini
   free-trial inside onboarding).** The single most-repeated verdict. Go beyond showing value:
   have them complete one actual unit of the core loop — do a lesson, generate one result, make a
   pick, explore the map — so they feel the product working before any gate. This interactive taste
   is itself the strongest conversion lever. *Exemplars:* Duolingo (finish a real first lesson
   before signup), Elma (try the core experience pre-signup), César's sign-language teardowns
   ("interactive lesson from the start"), Runkeeper (animation on open), Timehop (product-in-action).
2. **Engineer the emotional arc: problem → future-self → solution.** Make them feel the problem,
   frame who they become, position the app as the bridge. (César's spiky POV.)
3. **Collect data early — and make it visibly pay off in a personalized plan.** Every question
   feeds a named, personalized result so the paywall feels made-for-me. *Exemplars:* Speak
   ("in 2 months you'll communicate in France"), Byte Pal (plan + exact goal date), Endless,
   Brilliant, Headspace multi-intent (+10%), Dollar Shave Club conversational quiz (+5%),
   Grammarly tailored plans (+20%).
4. **The paywall is a flow, not a screen.** Sell the outcome first so it's the natural next step;
   multi-page beats single; reduce risk with a "how your trial works" timeline + "cancel anytime."
5. **Pricing architecture: annual-default, anchored, honest trial, with a "Most Popular" badge on
   the highest-LTV plan.** Two plans, annual pre-selected as the default *and* visually flagged
   "Most Popular / Recommended" (social proof + default-steering — a real, well-supported lever),
   monthly as the anchor, labeled trial. Badge the plan that's best for LTV (annual). (César's
   most-mentioned topic; 178 references; he repeatedly notes the yearly plan being highlighted.)
   *Honest line:* badging/defaulting the annual plan with both prices visible is fine; **hiding the
   cheaper plan, or badging a worse-value option "Most Popular," is the dark-pattern side** —
   flagged in `dark-patterns.md`.
6. **Polish & memorability are table stakes.** Animation, delight, a nameable mascot; even
   loading/verification states. Makes a long flow feel short. *Exemplars:* Bipul (nameable
   raccoon, 61 screens), Bump (animated loading states), Duolingo.
7. **Trust & momentum mechanics.** Social proof (Superhuman logos, Timely proof page), founder/
   human touches (One Year signature, Basecamp/Airbnb CEO note), permission priming before the OS
   prompt (Brilliant, Center), progress indicators + reassuring microcopy (Cake Equity), checklists
   for retention (Mural +10% one-week), effort-justification/IKEA-effect, review-ask at the peak.

**Two philosophies that override the pillars when they conflict:**
- **Length isn't the enemy — "feeling long" is.** Avg app = 25 screens; the best long flows
  (Duolingo ~60) don't feel long because of delight/personalization. Don't optimize for *short*.
- **Sometimes the best onboarding is none.** If the product speaks for itself (Mobbin, AI-chat
  where the first prompt is the value), get out of the way. The skill must be willing to
  recommend a minimal/no-onboarding path when the app calls for it.

**The tension the skill names explicitly (⚠️ headline example in `dark-patterns.md`):**
César's most-loved paywall lever — **escalating exit-offer discounts** ("close → 50% off → close
again → 80% off," 67 references) — is exactly the gray-zone pattern Mobbin's own skeptic, Apple,
and Filip flag as trust-eroding and bad for LTV. The skill surfaces it honestly: high-conversion,
high-risk, user's call. This collision between the anchor source and the ethics pole is the
neutral-menu-with-warnings stance in action.

## Goals

- From an app idea, decide **what onboarding questions are necessary** (name, age, goals,
  pains…), **how to sequence and word them**, and **how to engineer the emotional arc**
  (problem-awareness → future-self → personalized plan → earned paywall).
- Produce a portable, written **screen-by-screen flow spec** (text, no mockups).
- Also **audit** an existing flow (text or screenshots) against the same principles.
- Stay honest: principles traceable to sources; vendor stats framed as A/B hypotheses, not laws.

## Non-goals

- No visual/HTML mockups (text spec only).
- Not tailored to the Bible app (general-purpose; the Bible app is one validation case).
- Not a gatekeeper — it won't refuse aggressive patterns, only label + warn.

## Skill identity

- **Name:** `onboarding-architect`
- **Location:** user-level `~/.claude/skills/onboarding-architect/` (reusable across projects;
  developed in this repo, installed globally).
- **Trigger:** designing or critiquing app onboarding / paywall / activation flows
  (e.g. "design onboarding for my app", "what questions should signup ask", "audit this paywall").

## File layout

```
onboarding-architect/
  SKILL.md                      # trigger + interview + generation/audit procedure
  references/
    onboarding-principles.md    # sequencing, personalization, delight, permission priming
    paywall-levers.md           # trial design, plans, anchoring, "how your trial works"
    question-taxonomy.md        # ★ onboarding question types + strategic purpose + example copy
    emotional-arc.md            # ★ problem-awareness → future-self → plan → earned paywall
    dark-patterns.md            # labeled catalog + severity + trust/App-Store/legal risk
  corpus/                       # raw TEXT for verbatim citation (grep-able); no media
    cesar-breakdowns.txt, mobbin-*.txt, tim-gabe/*, will/alex/filip…
  templates/
    flow-spec.md                # output skeleton
```

The two ★ docs are the heart of the generation value. `corpus/` ships text only; media stays
in the project archive (`x-scrape/media/`).

## Generation procedure (SKILL.md core)

1. **Interview (~5 questions, via the question tool):**
   1. The transformation — who does the user *become* (before→after)?
   2. Buyer vs. user — who pays, who uses, whom must onboarding persuade?
   3. Monetization model — free trial / hard paywall / freemium / one-time; price if known.
   4. Primary conversion goal — trial start / paid / habit formation (the north-star).
   5. The one belief — what must the user believe by the time they hit the paywall?
2. **Derive strategy** (shown briefly): core desire, problem to make salient, future-self frame,
   what data is worth collecting and why each item earns its screen.
3. **Design the question set** from `question-taxonomy.md` — for each question: the wording, *why*
   it's there (personalize / problem-awareness / feed paywall / segment), and how to present it.
4. **Sequence & frame** per `onboarding-principles.md` + `emotional-arc.md`:
   hook → value taste → questions → "building your plan" delight → personalized plan reveal →
   trust beats → notification priming → paywall.
5. **Design the paywall** from `paywall-levers.md`: model, plans (annual default / anchor), trial +
   "how your trial works" timeline, framing levers — manipulative options labeled + risk-flagged.
6. **Emit the spec** (see Output).

Key idea: the interview feeds the emotional arc, and the emotional arc dictates which questions
are necessary.

## Audit mode (secondary)

Input: **text** (pasted screen sequence/copy) or **screenshots** (read via vision). Runs the same
principle set in reverse — maps each screen to levers used/missing, flags dark patterns with
severity, notes what works, gives prioritized fixes. A mode of the same skill, not a separate skill.
Unreadable screenshots: report which screens couldn't be parsed, audit the rest.

## Output — flow spec (`templates/flow-spec.md`)

```
# <App> — Onboarding & Paywall Flow
## Strategy (3–4 lines)      # core desire, problem, future-self frame, the belief
## The question set          # each Q: wording · why it's here · presentation
## The flow (screen-by-screen)
   N. <Screen name> [who it's for]
      Purpose · Copy (headline/sub/CTA) · Levers used
## The paywall               # model · plans · trial timeline · framing levers
## Levers & risks table       # each key choice → principle → source → conversion/risk note
## What this flow deliberately avoids   # dark patterns not used + why
```

Traceability lives in the "Levers & risks table" (appended, not inline, to keep the flow readable).

## Knowledge base — how it's built

**Sources:** the scraped corpus (César breakdowns w/ OCR'd screens; Mobbin's two studies —
1,460 onboarding flows / 4,700 paywalls, the richest single source; Tim Gabe teardowns; Will,
Alex, Filip). **Head start:** existing `docs/research/10` + `11` are already-distilled,
source-cited, fact-checked onboarding/paywall principles → they become the backbone; the scrape
broadens/generalizes them and the Bible-specific framing is stripped to general form.

**Process (per reference doc):** read across corpus → extract recurring principles/patterns →
cluster, dedupe, **attribute each to its source** (powers the citation layer).

**Evidentiary discipline (carried from doc 11's fact-check):** keep academic mechanisms as firm
principles (IKEA effect — Norton/Mochon/Ariely 2011; effort justification — Aronson & Mills 1959;
goal-gradient); mark single-app vendor stats ("+20%", "5×") as **directional A/B hypotheses, not
laws.**

**New synthesis:** `question-taxonomy.md` and `emotional-arc.md` are extracted primarily from
César's breakdowns + Mobbin's personalization findings. `dark-patterns.md` draws the Will pole +
Filip's critiques + Apple/FTC constraints into a labeled catalog with severity + risk.

**Preserve concrete exemplars.** Each principle in `onboarding-principles.md` / `paywall-levers.md`
must carry its **named app examples** (Elma, Runkeeper, Timehop, Duolingo, Headspace, Speak,
Byte Pal, Endless, Brilliant, Grammarly, Superhuman, One Year, Basecamp, Airbnb, Cake Equity,
Mural, Bump, Bipul, House, Tide, Focus Flight, Dollar Shave Club, plus César's teardown subjects)
— the skill reasons from precedent, and generated specs cite "like X does" rather than asserting
in the abstract. The two overriding philosophies (length ≠ enemy; sometimes no onboarding) and the
escalating-discount tension are captured verbatim, not smoothed away.

**Quality bar:** every principle traceable to a source; stats framed as hypotheses; ethical
warnings attached where relevant; named exemplars retained. Distillation naturally parallelizes
(one pass per reference doc); sequential-vs-parallel execution is a plan-level decision.

## Edge cases

- **Vague app idea** → interview resolves it; if still thin, state assumptions and proceed.
- **Mold-breakers** (B2B/team, one-time purchase, no-paywall/ad-supported, hardware) → adapt
  (e.g. no-paywall → optimize activation, not trial-start), don't force a subscription template.
- **User skips interview questions** → sensible defaults, flagged in the spec's assumptions.
- **Unreadable audit screenshots** → name the unparsed screens, audit the rest.

## Validation

- **Regression against hand-built work:** run on this Bible app; compare to `docs/research/11`.
  Success = independently reaching the same core moves (parent-buyer framing, taste-before-gate,
  trust beats, annual-default honest trial).
- **Breadth check:** generate for 2–3 archetypes (fitness tracker, AI writing tool, habit app);
  different apps must yield genuinely different question sets, not a reskin.
- **Audit check:** feed a known dark-pattern flow (Will's aggressive playbook, from the corpus);
  confirm it flags the manipulative levers with correct severity.
