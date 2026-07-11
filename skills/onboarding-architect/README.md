# onboarding-architect

A general-purpose Claude skill for **designing and auditing consumer-app onboarding + paywall flows**.
Give it an app idea and it interviews you briefly, then generates a screen-by-screen flow spec — what
questions to ask, how to sequence and word them, how to build the emotional arc, and how to structure
the paywall. Or give it an existing flow (text or screenshots) and it audits it against the same
principles. Works for any consumer app.

Stance: **neutral menu with warnings** — it surfaces every lever, including aggressive ones, and labels
manipulative patterns with their trust / App-Store / legal risk. It never refuses; it informs.

## What's inside

- `SKILL.md` — the orchestrator: Core Principles, the interview, the design + audit procedures.
- `references/` — the knowledge base:
  - `onboarding-principles.md` — sequencing, personalization, delight, permissions, when NOT to onboard
  - `paywall-levers.md` — the paywall-as-flow, pricing architecture, trials, framing, LTV
  - `question-taxonomy.md` — what to ask and why (the selection rule)
  - `emotional-arc.md` — problem → future-self → plan → earned paywall + the psychology
  - `dark-patterns.md` — labeled catalog + severities + platform/legal constraints
- `templates/flow-spec.md` — the output skeleton.
- `corpus/` — raw source material (studied teardowns + studies) for verbatim citation.

Principles are traceable to sources and carry named app exemplars; single-app vendor stats are labeled
directional hypotheses, not laws.

## Install

**Claude Code (any machine):** copy this `onboarding-architect/` folder into `~/.claude/skills/`, then
start a new session. Invoke it by asking to design or audit an onboarding/paywall flow.

**claude.ai:** Settings → Capabilities → Skills → upload this folder (or its zip).

## Invoke it with, e.g.
- "Design onboarding for my \<app\>."
- "What questions should my signup flow ask?"
- "How should I frame my paywall?"
- "Audit this onboarding/paywall." (paste the screens or attach screenshots)
