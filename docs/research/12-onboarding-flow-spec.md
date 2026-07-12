# True North — Onboarding & Paywall Flow

*Generated with the `onboarding-architect` skill. App: True North, a reverent Bible-story app for
ages 7–9 (Storybook-Cartography aesthetic; compass mascot "Poli"). Buyer = parent, user = child.
Conversion stats referenced below are **directional A/B hypotheses, not targets** — test them.*

## Strategy

- **Core desire:** evangelical parents desperately want to disciple their kids (≈70% say it's very
  important) but mostly don't (structure + confidence gap). They already pay for faith apps.
- **Problem to make salient:** the intention–execution gap — *"you already want this; you just don't
  have a trustworthy, repeatable way to do it 10 minutes a night."*
- **Future-self frame:** *"Every night, [child] hears a story from Scripture told faithfully — and
  brings the big questions to you."* Parent as the hero-guide, app as the bridge.
- **The one belief to earn by the paywall:** *"This is doctrinally safe and reverent, it will help me,
  and it will never try to replace me as the parent."* Trust — not desire — is the bottleneck, so we
  **invert the usual playbook: prove safety/reverence before asking for anything.**

## The question set

Trust-first inversion means the value taste comes *before* the quiz. Every question below either
personalizes the plan, surfaces/answers the parent's fear, or primes a permission — nothing collected
for its own sake, and each visibly pays off at the Plan Reveal or Parent Promise.

| Question | Why it's here | Wording | Presentation |
|---|---|---|---|
| Child's name | personalize — used in copy + plan everywhere after | "Who are we journeying with?" | single text field, conversational |
| Child's age (7 / 8 / 9) | personalize — sets reading level/content band; COPPA youngest-band design | "How old is [name]?" | 3 chips |
| **Bible translation** | personalize **+ trust** — retellings point to *their* Bible; answers "will it get it right?" | "Which Bible does your family read?" (ESV · KJV · NIV · CSB · Other) | single-select list |
| Current Bible-time habit | problem-awareness (grace-framed, no option shames) | "How does Bible time look in your home right now?" | single-select |
| Your hope for [name] | personalize — reflected in the plan's framing | "What do you most want [name] to carry with them?" | single-select / short |
| Your worry | surface **then answer** the objection on the Promise screen | "What makes you cautious about a Bible app?" (Get the Bible right? · Screen time · Safe & private? · Will it replace me?) | single-select |
| Reminder time (opt) | primes notification permission | "When's story time?" | time chips |

*Deliberately NOT asked:* email/child PII pre-gate (COPPA), anything that doesn't change the plan.

## The flow (screen-by-screen)

1. **Warm Welcome / Outcome Hook** [parent] — full-bleed map, Poli at "You are here."
   - Purpose: sell the outcome, not features; establish the world.
   - Copy: H "A gentle path through the Bible — one story at a time." · sub "Reverent retellings for
     ages 7–9, built to hand the big questions back to you." · quiet trust line "Reviewed by pastors.
     No ads. No chat. No data collected on your child." · CTA "Begin the journey."
   - Levers: outcome-not-features (Timehop); polish/world-building (pillar 6).

2. **Founder's Note** [parent] — handwritten-style note + real signature.
   - Purpose: human/founder touch → trust before any ask.
   - Copy: *"We're parents too. Every story here is told faithfully — never twisted, never quoted
     wrong. True North will never try to be your child's pastor; when they wonder about the hard
     things, it points them back to you. — [family], aligned with the BF&M 2000."*
   - Levers: founder touch (One Year / Basecamp); pillar 7 trust.

3. **Preview a Real Story — the "aha"** [parent, experiencing it as the child] — **the value taste.**
   - Purpose: **do the real thing once (pillar 1), buyer-facing.** The parent runs through one
     complete, audio-first reverent retelling (e.g. *The Storm That Obeyed*) exactly as [name] will —
     the narration, the illustration, and the closing **wondering-question** where Poli says *"That's a
     wonderful question for your grown-up. Ask them tonight,"* giving no answer. The parent *watches the
     app honor every promise.* **This screen is the sale.**
   - Copy: "Take a moment — walk through a story the way [name] will experience it." · CTA "Play the story."
   - Levers: do-the-real-thing-once (Duolingo first lesson, Elma try-before-signup); reciprocity
     (emotional-arc); proof-by-experience.

4. **Parental Gate** [the fork] — COPPA/Apple-Kids gate before quiz, purchase, links, permissions.
   - Copy: "Grown-ups, this next part's for you." Poli: "I'll wait here with the story." (hold/biometric gate)

5–9. **Parent Quiz** — the 7 questions above, presented one idea per screen, progress shown as a
   filling map path with the first segment already stamped complete (goal-gradient).
   - Levers: data-early→personalized-plan (pillar 3); conversational quiz (Dollar Shave Club, *hyp.*);
     multi-... kept single-select to stay fast; every answer reflected back at screen 11.

10. **Building [name]'s Journey** [delight, ~4s] — a gold route ink-draws across the map; Poli walks it.
    - Levers: delight makes a long flow feel short (pillar 6 / Bump loading states); IKEA-effect setup.

11. **[name]'s Journey — Plan Reveal** [parent] — the payoff.
    - Copy: "*[name]'s Journey — 12 weeks through the Story.*" Bullets reflect the quiz: "~10 min a
      night, at your pace — no streaks, no pressure. One wondering-question to talk over each night.
      Verses shown from your family's **[translation]**. Chosen to help [name] carry: *[their hope]*.
      Starting gently, since you're just beginning." First story shown ✓. CTA "This looks right."
    - Levers: show-what-answers-unlocked (Speak, Byte Pal, Endless); IKEA-effect (a plan they built).

12. **The Parent Promise** [trust keystone] — parchment scroll; the parent's **Q-worry pinned at top**,
    then 6 gold-check promises:
    1. Retells faithfully — never quotes Scripture wrong; verses shown from **your** translation.
    2. Reviewed by pastors; aligned with the BF&M 2000.
    3. Never gives your child spiritual advice — the big questions come home to *you*.
    4. No ads, no chat, no strangers.
    5. No data collected on your child; never used to train any AI.
    6. Cancel anytime, two taps.
    - CTA "I trust this — continue." Levers: reduce-risk (pillar 4); answers the exact objection surfaced.

13. **Social Proof** [parent] — real 4.8★, "Loved by N Christian families," 2–3 testimonials chosen to
    **name-and-resolve the AI fear** (*"I was nervous about AI near the Bible. But it just retells the
    stories — faithfully — and when she asked a hard question, it sent her to me. That sold me."*).
    - Levers: social proof (Superhuman/Timely); pillar 7.

14. **Notification Priming** [custom screen before OS prompt] — Poli with a lantern.
    - Copy: "Want a gentle nudge at story time? One quiet evening reminder — no guilt, no streaks. Off
      anytime." → "Yes, a gentle reminder / Not now." then the native prompt.
    - Levers: permission priming (Brilliant / Center).

15. **Paywall** [routed through the parent gate] — see below.

*Deliberately NOT here:* an App-Store rating prompt (defer to a real post-value milestone); any
in-character "unlock more adventures!" prompt shown to the child.

## The paywall

- **Model:** soft-then-hard **hybrid** — the parent has already previewed a full story; everything
  beyond unlocks via a free trial. A hard wall at app-open would read mercenary to a still-deciding
  parent (per LTV-not-signups; the "hard paywall 5×" figure is a survivorship-biased median, *hyp.*).
- **Plans (annual default + "Most Popular", monthly anchor, both prices visible):**
  - **Family Annual — $59.99/yr, 7-day free trial — pre-selected + "Most Popular" badge** → "*about $5/month.*"
  - **Monthly — $9.99/mo** (anchor; makes annual read ~50% off).
  - Quiet **See all plans** link (family option lives here). *Honest line: badge sits on the genuine
    best value with both prices shown — not hiding the cheap plan.*
- **Trial:** 7-day, standard StoreKit (bills via the parent's Apple ID). **No card-entry trap. No
  free-trial toggle** (Apple 3.1.2 rejects toggles). An explicit, labeled trial plan.
- **"How your free week works" timeline** (strongest risk-reducer, Apple-endorsed):
  **Today** — full access unlocks, $0 today → **Day 5** — friendly reminder your trial's ending →
  **Day 7** — $59.99/yr begins unless you've cancelled. Cancel anytime.
- **Value stack (structure/formation — never "AI"):** the full Story library (100+ retellings, growing)
  · [name]'s guided 12-week journey (~10 min/night) · a nightly wondering-question to talk over ·
  offline, no ads/chat/data · whole family, one subscription.
- **On-screen trust:** *cancel in two taps* · *we'll remind you before your trial ends — no surprise
  charges* · *reviewed by pastors • aligned with the BF&M • no AI trained on your child* · Restore
  Purchases + Manage Subscription visible.
- **CTA:** **"Start [name]'s free week."** sub *"No charge today. We'll remind you before day 7."*
  Secondary (never confirmshaming): **"Maybe later."**
- **Post-dismiss (grace):** one respectful one-time offer — a **longer trial, not a discount**
  (*"Take a little longer to decide — here's 14 days, on us."*). Shown once, then full price.

## Levers & risks table

| Choice | Principle | Source | Conversion note | Risk |
|---|---|---|---|---|
| Full story previewed before any gate | do-the-real-thing-once | César / Mobbin (Elma, Duolingo) | strongest lever; proof beats claims | none |
| Data-early quiz → named 12-week plan | data→personalized plan | Mobbin (Speak, Byte Pal) | plan feels made-for-me | none |
| Parent Promise answering the pinned worry | reduce-risk / trust | Blinkist risk-reduction | converts the trust bottleneck directly | none |
| Annual default + "Most Popular" badge, monthly anchor | pricing architecture | Mobbin / César | anchors annual as best value | none (both prices shown) |
| 7-day trial + "how your trial works" timeline | paywall-as-flow | Blinkist / Slopes | fewer "felt tricked"; more push opt-ins | none |
| Post-dismiss **longer trial** (not discount) | recovery / preserve trust | Mobbin skeptic | recovers deciders without eroding price | low — a longer trial, not a discount |
| No streaks; "no guilt" framing | grace brand / retention | — | fits buyer; avoids manipulation backlash | none |

## What this flow deliberately avoids

- **Escalating exit discounts (close→50%→80%)** — high-convert but high-risk (trust + LTV + Apple
  post-close-offer rejection, 3.1.2). *Offered in the corpus; rejected here* — replaced with a single
  longer-trial offer. (see `dark-patterns.md`)
- **Fake urgency / countdowns** — erodes trust; parents increasingly expect the after-offer.
- **Free-trial toggle** — Apple 3.1.2 rejection; use a labeled trial plan instead.
- **Confirmshaming** ("No, I don't want to disciple my child") — brand-toxic; secondary is neutral "Maybe later."
- **Hard-to-cancel / hidden cheap plan / weekly pricing** — FTC/trust risk; cancel in two taps, both prices visible.
- **Selling to the child in-character** — FTC/COPPA (Epic $275M); every purchase/link/permission sits behind the parent gate.
- **Harvesting or training AI on child input** — promised against explicitly (COPPA 2025).

## Assumptions (interview was rich; flagged where inferred)
- 12-week initial journey length and $59.99/$9.99 price points are placeholders to A/B test.
- Translation list (ESV/KJV/NIV/CSB/Other) assumed from a US-evangelical audience; expand as needed.
- "Poli" used as the compass mascot name per current app assets.
