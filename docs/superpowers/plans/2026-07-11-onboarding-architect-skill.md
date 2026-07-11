# onboarding-architect Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `onboarding-architect`, a general-purpose Claude skill that generates (and audits) app onboarding + paywall flows from a distilled, source-cited knowledge base mined from the César / Mobbin / Tim Gabe corpus.

**Architecture:** A `SKILL.md` orchestrator that leads with named Core Principles, runs a ~5-question interview, then generates a screen-by-screen flow spec by reasoning over five `references/*.md` knowledge docs. Raw text ships in `corpus/` for verbatim citation. Built in-repo at `skills/onboarding-architect/`, then symlinked into `~/.claude/skills/` so it's live across projects.

**Tech Stack:** Markdown only (skill + references + templates). Bash for scaffolding, corpus copy, and validation greps. No runtime code, no build step.

## Global Constraints

- **Skill dir (dev):** `skills/onboarding-architect/` in this repo. **Install target:** `~/.claude/skills/onboarding-architect` (symlink).
- **Scope:** general-purpose (any app); the Bible app is a validation case only — no SBC/BF&M/COPPA baked into the general docs.
- **Ethics stance:** neutral menu with warnings — surface every lever, label manipulative ones with trust/App-Store/legal risk; never refuse.
- **Output:** written screen-by-screen flow spec (text; no HTML/mockups).
- **Evidentiary discipline:** academic mechanisms (IKEA effect — Norton/Mochon/Ariely 2011; effort justification — Aronson & Mills 1959; goal-gradient) stated as principles; single-app vendor stats ("+20%", "5×") always labeled "directional A/B hypothesis, not a law."
- **Traceability:** every principle attributes its source; principles carry named app exemplars.
- **Core Principles (verbatim, keep top of mind):** (1) show-don't-explain / do the real thing once before the paywall; (2) emotional arc problem→future-self→solution; (3) collect data early → visible personalized plan; (4) paywall is a flow not a screen; (5) pricing = annual-default + anchor + honest trial + "Most Popular" badge on highest-LTV plan; (6) polish & memorability (animation, nameable mascot); (7) trust & momentum (social proof, founder touch, permission priming, checklists, review-at-peak). Overriding philosophies: length≠enemy ("feeling long" is); sometimes no onboarding is best.

**Source material (read-only inputs, in this repo):**
- `x-scrape/accounts/cesaralvarezll_BREAKDOWNS.txt` (anchor: captions + OCR'd screens)
- `x-scrape/accounts/cesaralvarezll.txt`, `filippkowalski.txt`, `alexcooldev.txt`, `athcanft.txt`, `YoniSmolyar.txt`
- `youtube-transcripts/mobbin/01_*paywalls*.txt`, `02_*Streaks*.txt`, `04_*Onboarding*.txt`
- `youtube-transcripts/tim-gabe/*.txt` (app-teardown subset)
- `docs/research/10-onboarding-paywall-principles.md`, `11-onboarding-paywall-flow-design.md` (already-distilled backbone — GENERALIZE, strip Bible-specifics)

---

### Task 1: Scaffold skill + assemble corpus

**Files:**
- Create: `skills/onboarding-architect/` (+ `references/`, `corpus/`, `templates/` subdirs)
- Create: `skills/onboarding-architect/corpus/` (populated from sources)
- Create: `skills/onboarding-architect/corpus/SOURCES.md`

**Interfaces:**
- Produces: the directory tree every later task writes into; `corpus/*.txt` files later tasks grep for citations.

- [ ] **Step 1: Create the tree**

```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
mkdir -p skills/onboarding-architect/{references,corpus,templates}
mkdir -p skills/onboarding-architect/corpus/tim-gabe
```

- [ ] **Step 2: Copy the clearly-relevant corpus text**

```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
S=skills/onboarding-architect/corpus
cp x-scrape/accounts/cesaralvarezll_BREAKDOWNS.txt $S/cesar-breakdowns.txt
cp x-scrape/accounts/cesaralvarezll.txt $S/cesar-tweets.txt
cp x-scrape/accounts/filippkowalski.txt $S/filip-ethics.txt
cp x-scrape/accounts/alexcooldev.txt $S/alex-pricing.txt
cp x-scrape/accounts/athcanft.txt $S/will-aggressive.txt
cp x-scrape/accounts/YoniSmolyar.txt $S/yoni-brainrot.txt
cp youtube-transcripts/mobbin/01_*paywalls*.txt $S/mobbin-paywalls-study.txt
cp youtube-transcripts/mobbin/02_*Streaks*.txt $S/mobbin-why-streaks.txt
cp youtube-transcripts/mobbin/04_*Onboarding*.txt $S/mobbin-onboarding-study.txt
```

- [ ] **Step 3: Copy the Tim Gabe app-teardown subset (skip Figma tutorials)**

```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
S=skills/onboarding-architect/corpus/tim-gabe
grep -lEi "onboard|paywall|psycholog|retention|gamif|addict|top 1%|app outlier|leaderboard" \
  youtube-transcripts/tim-gabe/*.txt | while read f; do cp "$f" "$S/$(basename "$f")"; done
echo "copied $(ls $S | wc -l | tr -d ' ') tim-gabe teardown files"
```

- [ ] **Step 4: Write `corpus/SOURCES.md`** (provenance so citations are traceable)

```markdown
# Corpus sources
- cesar-breakdowns.txt — @cesaralvarezll, onboarding/paywall teardowns (captions + OCR'd screens)
- cesar-tweets.txt — @cesaralvarezll full timeline captions
- filip-ethics.txt — @filippkowalski, dark-pattern / ethics lens
- alex-pricing.txt — @alexcooldev, pricing / anti-underpricing
- will-aggressive.txt — @athcanft, aggressive hard-paywall / weekly-pricing playbook
- yoni-brainrot.txt — @YoniSmolyar, indie onboarding (worked example)
- mobbin-onboarding-study.txt — Mobbin "1,460 Onboarding Flows"
- mobbin-paywalls-study.txt — Mobbin "2,995 Paywalls / 4,700+"
- mobbin-why-streaks.txt — Mobbin streaks/retention
- tim-gabe/*.txt — Tim Gabe app teardown subset
```

- [ ] **Step 5: Verify corpus assembled**

Run:
```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
ls skills/onboarding-architect/corpus/*.txt | wc -l   # expect >= 9
test -s skills/onboarding-architect/corpus/cesar-breakdowns.txt && echo "anchor present"
ls skills/onboarding-architect/corpus/tim-gabe/*.txt | wc -l   # expect >= 5
```
Expected: ≥9 top-level corpus files, "anchor present", ≥5 tim-gabe files.

- [ ] **Step 6: Commit**

```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
git add skills/onboarding-architect/corpus
git commit -m "feat(skill): scaffold onboarding-architect + assemble corpus"
```

---

### Task 2: `references/onboarding-principles.md`

**Files:**
- Create: `skills/onboarding-architect/references/onboarding-principles.md`
- Read: `corpus/mobbin-onboarding-study.txt`, `corpus/cesar-breakdowns.txt`, `docs/research/10-onboarding-paywall-principles.md`

**Interfaces:**
- Produces: `onboarding-principles.md` — SKILL.md Step 4 (sequence & frame) reads it. Must contain the H2 anchors `## Sequence`, `## Personalization`, `## Delight & memorability`, `## Trust & momentum`, `## Permissions`, `## When NOT to onboard`.

- [ ] **Step 1: Author the doc.** Synthesize from the three sources. GENERALIZE doc 10 (strip Bible-specifics). Required content, each principle as `**Principle** — explanation. *Exemplar(s):* … *Evidence:* [source; stat labeled hypothesis if vendor-reported].`

  Must include these principles (all mined; do not drop any):
  - **The aha-moment arc:** signup → setup → aha (feel the value). *Exemplars:* Airbnb (first booking), Netflix (watch a show), Mobbin (save a screen).
  - **Sell the outcome, not features.** *Exemplars:* Timehop (product-in-action welcome), Runkeeper (animation on open), Superhuman (logos as social proof on signup).
  - **Do the real thing once before the paywall (mini free-trial in onboarding).** *Exemplars:* Elma (try core experience pre-signup), Duolingo (finish a real first lesson before account), César's sign-language teardowns ("interactive lesson from the start").
  - **Personalize, and make it worth their time** — only 23% of apps do (AI apps 7%). Multi-intent (Headspace multiple goals, +10% trial — *hypothesis*), conversational quiz copy (Dollar Shave Club +5% — *hypothesis*), let them shape the app (Focus Flight map style), Tide (2 questions → customized recs).
  - **Show what the answers unlocked — a personalized plan/result before they use it.** *Exemplars:* Endless (6 Qs → result), Byte Pal (plan + exact goal date), Brilliant (personalized courses, pre-populated home), Speak ("in 2 months you'll communicate in France" + graph; had you speaking not typing).
  - **Make a long flow feel short with delight.** *Exemplars:* Duolingo (~60 screens, doesn't feel long), Bump (animated loading/verification states), Bipul (61 screens, nameable raccoon).
  - **Human / founder touches at the aha moment.** *Exemplars:* One Year (handwritten signature + drawn flower), Basecamp (CEO note post-signup), Airbnb (CEO video after first listing), Tinder (birthday acknowledgment).
  - **Guide step-by-step; don't front-load education.** *Exemplars:* Cake Equity (tooltips, reassuring copy, real-time password validation), To-do apps (populated example vs blank state, one nudge).
  - **Checklists beat pop-ups for retention.** *Exemplar:* Mural (6-step checklist → +10% one-week retention — *hypothesis*; checklists persist after dismissal).
  - **Prime permissions with a custom screen before the OS prompt.** *Exemplars:* Brilliant ("I'll remind you so it becomes a habit"), Center (teases the actual notification). (Web onboarding ~21% shorter than iOS — fewer permission/paywall screens.)
  - **Splitting a form across screens can raise conversion.** *Exemplar:* House (+15% — *hypothesis*). Friction in one place can remove it elsewhere.
  - **Culture matters** — info-dense UIs read as efficient in some Eastern markets; don't blind-copy.
  - **`## When NOT to onboard`:** if the product speaks for itself (Mobbin, AI-chat where first prompt = value), minimize/skip onboarding. Length ≠ enemy; "feeling long" is (avg app = 25 screens; longest = finance/health/education).

- [ ] **Step 2: Verify structure + exemplars present**

Run:
```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
D=skills/onboarding-architect/references/onboarding-principles.md
for h in "## Sequence" "## Personalization" "## Delight" "## Trust" "## Permissions" "## When NOT to onboard"; do grep -q "$h" "$D" && echo "ok: $h" || echo "MISSING: $h"; done
for x in Duolingo Elma Headspace Speak "Byte Pal" Mural Brilliant Cake Bipul Timehop; do grep -q "$x" "$D" && echo "ok: $x" || echo "MISSING: $x"; done
grep -qi "hypothesis" "$D" && echo "ok: stats labeled" || echo "MISSING: stat labeling"
```
Expected: every `ok:` line, no `MISSING:`.

- [ ] **Step 3: Commit**

```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
git add skills/onboarding-architect/references/onboarding-principles.md
git commit -m "feat(skill): onboarding-principles reference"
```

---

### Task 3: `references/paywall-levers.md`

**Files:**
- Create: `skills/onboarding-architect/references/paywall-levers.md`
- Read: `corpus/mobbin-paywalls-study.txt`, `corpus/cesar-breakdowns.txt`, `corpus/alex-pricing.txt`, `docs/research/10-onboarding-paywall-principles.md`

**Interfaces:**
- Produces: `paywall-levers.md` — SKILL.md Step 5 reads it. H2 anchors: `## The paywall is a flow`, `## Pricing architecture`, `## Trial design`, `## Framing levers`, `## Recovery (exit offers)`, `## Optimize for LTV not signups`.

- [ ] **Step 1: Author the doc.** GENERALIZE doc 10 §B. Required principles (each with exemplar + evidence, stats labeled hypotheses):
  - **The paywall is a flow, not a screen — users decide before they see it.** Sell the outcome first. *Exemplar:* Opal ("get 8 years of your life back" → trial 7%→17% — *hypothesis*).
  - **Multi-page beats single-page** — let information unfold.
  - **Reduce risk → convert.** "How your trial works" timeline (Blinkist — fewer "felt tricked", more push opt-ins); "no commitment, cancel anytime" subtitle. Now Apple-endorsed; toggle paywalls rejected (Apple 3.1.2, 2026).
  - **Presentation > offer.** *Exemplar:* Tipstop (same offer, better trial emphasis + discount badge + copy → ~3× — *hypothesis*).
  - **The "pay ramp."** *Exemplar:* Slopes ("Redeem your free week" single action → +25% trial starts — *hypothesis*).
  - **Pricing architecture:** default to ANNUAL (highest LTV); show TWO plans (hide rest behind "see all plans"); monthly as anchor so annual reads ~50% off; **"Most Popular / Recommended" badge on the highest-LTV plan** (social proof + default-steering). César repeatedly notes the yearly plan visually highlighted (e.g. "89% off").
  - **Trial length:** longer can beat shorter. *Exemplar:* Headspace 7/14/30 → 14-day on annual won (— *hypothesis*). 7-day trial→paid ~37–45% vs ~25–30% for 3-day (*directional*).
  - **Framing levers:** social proof (real reviews + 5-star; Timely's full proof page), value framing ("selling different futures"), price anchoring (per-week breakdown; "less than a coffee").
  - **Friction can filter for quality.** *Exemplar:* Outsider (card-for-trial halved signups but 5×'d conversion = 2× payers — *hypothesis*, Day-35 survivorship-biased).
  - **Recovery / exit offers:** a post-dismiss one-time offer can lift revenue. Prefer a **longer trial** over discounts to preserve trust. NOTE the tension (goes in dark-patterns.md): César's escalating "close→50%→80%" discounts are high-convert / high-risk.
  - **`## Optimize for LTV not signups`:** north star = revenue per paywall view + first-renewal retention, not trial-starts. No universal best paywall — only better experiments; radical design tests move the needle most.

- [ ] **Step 2: Verify**

Run:
```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
D=skills/onboarding-architect/references/paywall-levers.md
for h in "## The paywall is a flow" "## Pricing architecture" "## Trial design" "## Framing levers" "## Recovery" "## Optimize for LTV"; do grep -q "$h" "$D" && echo "ok: $h" || echo "MISSING: $h"; done
for x in "Most Popular" annual anchor Opal Slopes Headspace "cancel anytime"; do grep -qi "$x" "$D" && echo "ok: $x" || echo "MISSING: $x"; done
grep -qi "hypothesis" "$D" && echo "ok: stats labeled" || echo "MISSING: stat labeling"
```
Expected: no `MISSING:`.

- [ ] **Step 3: Commit**

```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
git add skills/onboarding-architect/references/paywall-levers.md
git commit -m "feat(skill): paywall-levers reference"
```

---

### Task 4: `references/question-taxonomy.md` (★)

**Files:**
- Create: `skills/onboarding-architect/references/question-taxonomy.md`
- Read: `corpus/cesar-breakdowns.txt`, `corpus/mobbin-onboarding-study.txt`

**Interfaces:**
- Produces: `question-taxonomy.md` — SKILL.md Step 3 reads it to select the question set. H2 anchors: `## Question categories`, `## Selection rule`, `## Wording & presentation`.

- [ ] **Step 1: Author the doc.** This is a NEW synthesis — the catalog of onboarding-question TYPES, each with strategic purpose and example wording. Required categories (each: *purpose*, *why it converts*, *2–3 example phrasings*, *presentation format*):
  - **Identity / who-are-you** (name, role) — personalization anchor; used in copy everywhere after. *Format:* single text field, conversational.
  - **Demographic-for-personalization** (age, gender, experience level) — ONLY if it changes the plan/content; never vanity. *Format:* single-select chips.
  - **Goal / intent** — the transformation they want; allow **multi-intent** (Headspace +10% — *hypothesis*). *Format:* multi-select.
  - **Pain / problem** — surfaces the problem so the app can solve it (feeds emotional arc). *Example:* "What's hardest about X right now?" *Format:* single/multi-select.
  - **Current-state / baseline** — where they are now (grace-framed, no option shames); makes progress measurable. *Format:* single-select.
  - **Commitment / effort** (time per day, reminder time) — goal-gradient + primes notification opt-in. *Format:* slider / chips.
  - **Preference / customization** (theme, style) — ownership before use (Focus Flight map style). *Format:* visual picker.
  - **Segmentation** (source, use-case) — routes to tailored copy/plan; may feed pricing.
  - **`## Selection rule`:** include a question ONLY if its answer (a) personalizes the plan, (b) makes the problem salient, (c) primes a permission, or (d) feeds pricing/segmentation. If it does none, cut it. Every question must visibly pay off later (show what it unlocked).
  - **`## Wording & presentation`:** conversational > clinical (Dollar Shave Club +5% — *hypothesis*); one idea per screen; show progress; a mascot can ask the questions (César: "mascot guides the questionnaire"); reflect answers back at the plan reveal.

- [ ] **Step 2: Verify**

Run:
```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
D=skills/onboarding-architect/references/question-taxonomy.md
for h in "## Question categories" "## Selection rule" "## Wording"; do grep -q "$h" "$D" && echo "ok: $h" || echo "MISSING: $h"; done
for x in Identity Goal Pain Commitment multi-intent; do grep -qi "$x" "$D" && echo "ok: $x" || echo "MISSING: $x"; done
grep -qi "only if" "$D" && echo "ok: selection rule stated" || echo "MISSING: selection rule"
```
Expected: no `MISSING:`.

- [ ] **Step 3: Commit**

```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
git add skills/onboarding-architect/references/question-taxonomy.md
git commit -m "feat(skill): question-taxonomy reference"
```

---

### Task 5: `references/emotional-arc.md` (★)

**Files:**
- Create: `skills/onboarding-architect/references/emotional-arc.md`
- Read: `corpus/cesar-breakdowns.txt`, `corpus/yoni-brainrot.txt`

**Interfaces:**
- Produces: `emotional-arc.md` — SKILL.md Steps 2 & 4 read it. H2 anchors: `## The arc`, `## Beat-by-beat`, `## Psychological mechanisms`.

- [ ] **Step 1: Author the doc.** NEW synthesis of César's spiky POV + Yoni's worked example. Required content:
  - **`## The arc`:** problem-awareness → agitate → future-self / aspiration → personalized plan (the bridge) → proof/trust → earned paywall. State César's thesis verbatim in spirit: *make the user realize they have a problem, then position the app as the solution; collect data early so the paywall feels personalized.*
  - **`## Beat-by-beat`** (map to screens), using Yoni/Brainrot's actual sequence as the worked example: opens with a product demo → clearly shows the problem → collects user data early → explains how the app solves it → asks for a review mid-onboarding → paywall. Give each beat: its job, the emotion targeted, and a copy pattern.
  - **`## Psychological mechanisms`** (named, cited): goal-gradient (progress accelerates commitment); IKEA effect / effort justification (a plan they helped build feels more valuable — Norton/Mochon/Ariely 2011; Aronson & Mills 1959); loss-framing / future-self; reciprocity (give a free win first); peak-end (review-ask at the emotional peak).
  - Cross-reference: the arc dictates which questions from `question-taxonomy.md` are necessary.

- [ ] **Step 2: Verify**

Run:
```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
D=skills/onboarding-architect/references/emotional-arc.md
for h in "## The arc" "## Beat-by-beat" "## Psychological mechanisms"; do grep -q "$h" "$D" && echo "ok: $h" || echo "MISSING: $h"; done
for x in problem future-self "goal-gradient" "IKEA" reciprocity Brainrot; do grep -qi "$x" "$D" && echo "ok: $x" || echo "MISSING: $x"; done
```
Expected: no `MISSING:`.

- [ ] **Step 3: Commit**

```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
git add skills/onboarding-architect/references/emotional-arc.md
git commit -m "feat(skill): emotional-arc reference"
```

---

### Task 6: `references/dark-patterns.md`

**Files:**
- Create: `skills/onboarding-architect/references/dark-patterns.md`
- Read: `corpus/filip-ethics.txt`, `corpus/will-aggressive.txt`, `corpus/cesar-breakdowns.txt`, `docs/research/10-onboarding-paywall-principles.md` §C

**Interfaces:**
- Produces: `dark-patterns.md` — SKILL.md reads it for the warning layer (generation) and severity flags (audit). H2 anchors: `## Catalog`, `## The escalating-discount tension`, `## Platform/legal constraints`.

- [ ] **Step 1: Author the doc.** `## Catalog` — each pattern as a row: *name · what it is · why it converts short-term · risk (trust / App-Store / legal) · severity (low/med/high)*. Must include:
  - Fake urgency / countdown timers (users now close paywalls expecting the after-offer) — med.
  - Spin-the-wheel / fake "you won a discount" — high (sleazy; short-term weekly-revenue lever).
  - Free-trial **toggle** paywalls — high (Apple rejects, 3.1.2, 2026).
  - Confirmshaming opt-outs ("No, I don't want to save money") — med.
  - Hard-to-cancel / asymmetric cancellation (ClassPass 17 screens) — high.
  - Hidden cheap plan / pre-selected priciest single option / badging a worse-value plan "Most Popular" — high.
  - Weekly pricing designed to hide the charge + no-notifications + targeting insecurity ("Am I attractive?") — high (Will's playbook, `will-aggressive.txt`).
  - Selling to / upselling a child in-character — high (FTC; Epic $275M).
  - **`## The escalating-discount tension`** (headline): César's most-loved lever — "close paywall → 50% off → close again → 80% off" — converts strongly short-term but is the same mechanism Mobbin's skeptic, Apple, and Filip flag as trust/LTV-eroding. Present BOTH sides; verdict = high-conversion / high-risk, user's explicit call. This IS the neutral-menu-with-warnings stance.
  - **`## Platform/legal constraints`:** Apple 3.1.2 (no trial toggles), COPPA (kids PII/consent), FTC dark-patterns report. Framed as constraints to warn on, not brand rules.

- [ ] **Step 2: Verify**

Run:
```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
D=skills/onboarding-architect/references/dark-patterns.md
for h in "## Catalog" "## The escalating-discount tension" "## Platform"; do grep -q "$h" "$D" && echo "ok: $h" || echo "MISSING: $h"; done
for x in urgency toggle confirmshaming cancel "Most Popular" escalating severity; do grep -qi "$x" "$D" && echo "ok: $x" || echo "MISSING: $x"; done
```
Expected: no `MISSING:`.

- [ ] **Step 3: Commit**

```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
git add skills/onboarding-architect/references/dark-patterns.md
git commit -m "feat(skill): dark-patterns catalog + escalating-discount tension"
```

---

### Task 7: `templates/flow-spec.md` (output skeleton)

**Files:**
- Create: `skills/onboarding-architect/templates/flow-spec.md`

**Interfaces:**
- Produces: `flow-spec.md` — SKILL.md Step 6 fills this in. Consumed structurally (headings copied into output).

- [ ] **Step 1: Author the skeleton** exactly matching the spec's Output section, with inline `<!-- guidance -->` comments per section:

```markdown
# <App> — Onboarding & Paywall Flow

## Strategy
<!-- 3–4 lines: core desire · problem made salient · future-self frame · the one belief needed by the paywall -->

## The question set
<!-- table: Question | Why it's here (personalize/problem/permission/pricing) | Wording | Presentation format -->

## The flow (screen-by-screen)
<!-- N. <Screen name> [who it's for: user/buyer]
     Purpose · Copy (headline / sub / CTA) · Levers used (cite principle) -->

## The paywall
<!-- model (soft/hard/hybrid) · plans (annual default + Most Popular badge, monthly anchor) ·
     trial + "how your trial works" timeline · framing levers -->

## Levers & risks table
<!-- table: Choice | Principle | Source (Cesar/Mobbin/…) | Conversion note | Risk (if any) -->

## What this flow deliberately avoids
<!-- dark patterns not used + one-line why; note any high-risk levers offered-but-flagged -->
```

- [ ] **Step 2: Verify all six sections present**

Run:
```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
D=skills/onboarding-architect/templates/flow-spec.md
for h in "## Strategy" "## The question set" "## The flow" "## The paywall" "## Levers & risks" "## What this flow deliberately avoids"; do grep -q "$h" "$D" && echo "ok: $h" || echo "MISSING: $h"; done
```
Expected: no `MISSING:`.

- [ ] **Step 3: Commit**

```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
git add skills/onboarding-architect/templates/flow-spec.md
git commit -m "feat(skill): flow-spec output template"
```

---

### Task 8: `SKILL.md` (orchestrator)

**Files:**
- Create: `skills/onboarding-architect/SKILL.md`

**Interfaces:**
- Consumes: all five `references/*.md`, `templates/flow-spec.md`, `corpus/*` (grep for citations).
- Produces: the skill entrypoint. Frontmatter `name: onboarding-architect` + `description:` with trigger phrases.

- [ ] **Step 1: Author SKILL.md** with these sections in order:
  1. **Frontmatter:** `name: onboarding-architect`; `description:` "Use when designing or auditing app onboarding, paywall, or activation flows — e.g. 'design onboarding for my app', 'what questions should signup ask', 'audit this paywall'. Generates a screen-by-screen flow spec grounded in studied onboarding/paywall principles."
  2. **Core Principles** — the 7 pillars + 2 overriding philosophies, verbatim from Global Constraints. "Check every generated flow against these; every audit evaluates against these."
  3. **Mode detection:** design (app idea / "design onboarding") vs audit (existing flow given as text or screenshots).
  4. **Design procedure (6 steps)** exactly per spec: (1) interview ~5 Qs via the question tool [transformation; buyer vs user; monetization model; primary conversion goal; the one belief]; (2) derive strategy (core desire, problem, future-self, data worth collecting) and show briefly; (3) design question set from `references/question-taxonomy.md`; (4) sequence & frame from `references/onboarding-principles.md` + `references/emotional-arc.md`; (5) design paywall from `references/paywall-levers.md`, labeling manipulative options via `references/dark-patterns.md`; (6) emit `templates/flow-spec.md`, filled.
  5. **Audit procedure:** read text or screenshots (vision); map each screen to levers used/missing; flag dark patterns w/ severity from `references/dark-patterns.md`; list what works; prioritized fixes.
  6. **Citation rule:** cite named exemplars ("like Duolingo/Speak…") from references; grep `corpus/` only when a verbatim quote is needed. Label vendor stats as hypotheses.
  7. **Edge cases:** vague idea → interview resolves, else state assumptions; mold-breakers (B2B/one-time/no-paywall/hardware) → adapt (no-paywall → optimize activation); skipped Qs → defaults, flagged; unreadable screenshots → name unparsed, audit rest.

- [ ] **Step 2: Verify frontmatter + section presence + reference wiring**

Run:
```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
D=skills/onboarding-architect/SKILL.md
head -5 "$D" | grep -q "name: onboarding-architect" && echo "ok: name" || echo "MISSING: name"
grep -q "description:" "$D" && echo "ok: desc" || echo "MISSING: desc"
for h in "Core Principles" "interview" "audit" "question-taxonomy.md" "emotional-arc.md" "paywall-levers.md" "onboarding-principles.md" "dark-patterns.md" "flow-spec.md"; do grep -q "$h" "$D" && echo "ok: $h" || echo "MISSING: $h"; done
```
Expected: no `MISSING:`.

- [ ] **Step 3: Commit**

```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
git add skills/onboarding-architect/SKILL.md
git commit -m "feat(skill): SKILL.md orchestrator"
```

---

### Task 9: Install + validate (functional test)

**Files:**
- Create: `~/.claude/skills/onboarding-architect` (symlink)
- Create: `skills/onboarding-architect/VALIDATION.md` (records the three checks)

**Interfaces:**
- Consumes: the whole skill. This is the real functional test of the spec's Validation section.

- [ ] **Step 1: Symlink into the user skills dir**

```bash
ln -sfn /Users/graceyan/Desktop/alpha/bible-slm/skills/onboarding-architect ~/.claude/skills/onboarding-architect
ls -l ~/.claude/skills/onboarding-architect && echo "linked"
```

- [ ] **Step 2: Regression test — run the skill on the Bible app, compare to doc 11.** In a fresh Claude session (or subagent), invoke the skill with the Bible-app idea (kids' Bible-study app, ages 7–9, parent-buyer, trust-as-bottleneck, subscription). Capture output to `skills/onboarding-architect/VALIDATION.md`. PASS if it independently reaches the core moves in `docs/research/11-onboarding-paywall-flow-design.md`: taste-before-gate, data→personalized plan, trust beats, annual-default honest trial, no dark patterns. Record hits/misses.

- [ ] **Step 3: Breadth test — 3 archetypes.** Invoke for (a) a fitness tracker, (b) an AI writing tool, (c) a habit app. PASS if the three question sets are genuinely different (not a reskin) and each cites archetype-appropriate exemplars. Record in VALIDATION.md.

- [ ] **Step 4: Audit test — dark-pattern flow.** Feed the skill Will's aggressive playbook (from `corpus/will-aggressive.txt`: hard paywall, weekly pricing to hide the charge, no notifications, insecurity targeting). PASS if it flags the manipulative levers with correct severity. Record in VALIDATION.md.

- [ ] **Step 5: Fix any gaps** found in Steps 2–4 by editing the relevant `references/*.md` or `SKILL.md`, then re-run the failing check. (Common fixes: a missing exemplar, an under-specified procedure step.)

- [ ] **Step 6: Commit**

```bash
cd /Users/graceyan/Desktop/alpha/bible-slm
git add skills/onboarding-architect/VALIDATION.md
git commit -m "test(skill): validation — regression, breadth, audit"
```

---

## Notes for the implementer
- Tasks 2–6 are independent authoring passes over the corpus — they can be parallelized (one subagent per reference doc) since none consumes another's output. Tasks 7–8 depend on all references existing; Task 9 depends on everything.
- Keep each reference doc focused and self-contained (one responsibility). If a doc grows unwieldy, that's a signal it's absorbing another doc's job.
- Do NOT bake Bible-app specifics into the general references; the Bible app is only Task 9's regression fixture.
