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

**Quality bar:** every principle traceable to a source; stats framed as hypotheses; ethical
warnings attached where relevant. Distillation naturally parallelizes (one pass per reference doc);
sequential-vs-parallel execution is a plan-level decision.

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
