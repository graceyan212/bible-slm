# Validation — onboarding-architect

Three cold tests (fresh agents invoking the installed skill, following SKILL.md + references only).
Artifacts in `validation-artifacts/`.

## 1. Regression vs. hand-built flow — PASS
Generated a flow for the kids' Bible-study app **blind** (agent forbidden from reading
`docs/research/11`). Independently reproduced every core move of the hand-built doc-11 flow:
- Full story **tasted before any gate** (the strongest lever).
- 6 scoped questions → a **named personalized plan** reflecting each answer.
- A dedicated **trust screen** serving the "one belief" ("a companion, not a substitute").
- Paywall: **annual $60 default + "Most Popular" badge + monthly anchor** (both prices visible),
  7-day trial with a Blinkist-style **"how your trial works" timeline**, no forced same-session close.
- Explicitly **rejected** escalating discounts, countdown urgency, confirmshaming, trial toggles;
  treated "never solicit the child" as a hard COPPA/FTC constraint.
→ `validation-artifacts/regression-bible.md`

## 2. Breadth across archetypes — PASS
Fitness tracker / AI writing tool / habit-builder produced **genuinely different** flows, not a reskin:
- Question counts 6 / 3 / 6; different questions **cut** per archetype (AI tool dropped name +
  demographics + commitment, deferring personalization to usage per the "AI apps personalize least"
  finding); habit app **added** an ownership/companion question to offset having no trial.
- Structurally different paywall models (soft pay-ramp vs. metered freemium vs. hard wall + refund).
- Archetype-appropriate exemplars cited (Slopes/Blinkist for fitness; Grammarly for AI; Brainrot
  escalating-discount flagged high-risk for habit).
→ `validation-artifacts/breadth.md`

## 3. Audit of a dark-pattern flow — PASS
Audited the aggressive playbook (`corpus/will-aggressive.txt`). Flagged the manipulative levers with
catalog-matching severities: obscured weekly pricing **High**, no renewal reminders **High**,
insecurity-targeting copy **High**, no-trial **Med**, hard-paywall-at-open **Med** (Filip ASO citation).
Mapped the flow to the 7 Core Principles, credited what genuinely works (neutral stance), and gave 5
prioritized fixes each citing its principle/source.
→ `validation-artifacts/audit-will.md`

## Verdict
The skill generates bespoke, principle-grounded flows; adapts across archetypes rather than
templating; reproduces expert hand-work independently; and audits with correctly-severitied,
non-preachy findings. Knowledge base sound; no gaps requiring fixes.
