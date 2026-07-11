# Onboarding Architect — breadth validation (3 apps, Design procedure)

Interview answers were pre-supplied per app (see one-liners in the task). Each section below covers
Step 2 (Strategy), Step 3 (question set), and Step 5 (paywall) only — screen-by-screen sequencing
(Step 4) is skipped per instructions.

---

## App A — Fitness tracker

**Interview (pre-answered):** transformation = sporadic exerciser → someone with a consistent workout
habit; buyer = user (solo consumer); monetization = subscription + 7-day free trial; conversion goal =
trial start; one belief needed by paywall = "this app makes consistency easy *for my life specifically*
— past attempts failed from generic plans and no accountability, not from lack of effort."

### Strategy
Core desire: identity as someone who reliably keeps a promise to themselves, not a specific aesthetic
outcome. Problem to make salient: past fitness attempts died from generic plans, no accountability, and
life getting in the way — not from lack of willpower. Future-self frame: the version of them with an
unbroken streak who "just does it," proven by a real completed workout inside onboarding itself, not a
promise. Data worth collecting: fitness baseline, schedule/time budget, past-failure reason, and daily
commitment — each must visibly reshape the plan (intensity, schedule, reminder time) since trial-start is
the KPI and a plan that feels made-for-me is what gets someone to tap "start trial" instead of "maybe
later."

### The question set

| Question | Why it's here | Wording | Presentation |
|---|---|---|---|
| Name | identity anchor — personalizes every later screen | "What should we call you?" | single free-text, mascot-voiced |
| Current activity level | personalizes plan (a) — sets starting intensity, avoids shaming | "How would you describe where you're at right now?" (Rarely active / Somewhat active / Very active) | single-select, neutral low-to-high labels |
| Goal / intent | personalizes plan (a) — real goals are plural | "What are you hoping to get from working out?" (Lose weight / Build strength / More energy / Just be consistent for once — pick all that apply) | multi-select cards, Headspace-style |
| Pain / what's stopped you before | makes problem salient (b) — the agitate beat needs the user's own words | "What's derailed you in the past?" (No time / Plans felt generic / Lost motivation after a few days / No one to answer to) | single-select, feeds copy on the plan-reveal screen |
| Daily time budget | personalizes plan (a) + primes permission (c) — commitment right before the reminder ask | "How much time can you realistically give this, most days?" (10 min / 20 min / 30 min / 45+ min) | discrete chips, not free text |
| Reminder time | primes permission (c) — sets up the notification pre-prompt | "When should I check in with you?" | time picker, immediately followed by a custom pre-permission screen before the OS dialog |

Cut: no demographic age/gender question — nothing downstream (calorie targets, difficulty tiers) actually
depends on it for this app's stated scope, so per the Selection rule it's friction with no payoff.

### The paywall
- **Model:** soft, trial-first — the KPI is trial starts, so the ask is framed as "start your free week,"
  not "buy a subscription." Consider a Slopes-style **pay-ramp** ("Redeem your free week") in place of a
  traditional paywall screen to strip friction from exactly the metric being optimized.
- **Plans:** Annual $47.99/yr (≈$0.92/wk) — default, badged **"Most Popular"** · Monthly $9.99/mo — anchor,
  visible, one tap away · additional 3-month tier hidden behind "see all plans."
- **Trial:** 7 days, full access. "How your trial works" timeline (Blinkist-style): Today: full access →
  Day 5: reminder notification → Day 7: charge unless canceled. No trial-toggle UI (Apple 3.1.2 risk) —
  a plain "Start free trial" button with the timeline shown alongside it.
- **Framing:** "No commitment, cancel anytime" subtitle (Mobbin dataset pattern); weekly-equivalent price
  anchoring next to the annual price; social proof (star rating / review count) directly above the CTA.
- **CTA:** "Start my free week" · secondary: "Not now" (never confirmshaming).
- **Flagged-but-not-used:** an escalating exit-discount ladder on dismissal would likely lift trial-starts
  further, but it's the wrong lever here — Apple now rejects the "offer after close" pattern outright, and
  because the KPI is trial-*start* (not immediate revenue), a longer/clearer trial offer beats a discount
  ladder per the "prefer longer trial over discount as recovery" principle.

---

## App B — AI writing tool

**Interview (pre-answered):** transformation = anxious/slow writer → fast, confident writer who ships
without second-guessing; buyer/user split: solo prosumer usually pays for themselves, but the product is
also sold to teams (a team admin becomes the buyer for a different cohort of users); monetization =
freemium with paid upgrade; conversion goal = activation first, upgrade second; one belief needed = "this
tool understands my writing and makes me visibly faster/better on my own text, immediately."

### Strategy
Core desire: the confidence and speed of a strong writer, without the dread of the blank page or the fear
of sounding unpolished. Problem to make salient: the blank-page freeze and the slow, self-doubting edit
loop — not a lack of vocabulary. Future-self frame: someone who drafts fast, hits send without three
re-reads, and gets told their writing sounds sharper. Data worth collecting: minimal and fast — this is an
AI tool, and the dataset shows AI apps personalize least (7%) because the product should learn from real
usage rather than a quiz. The one thing worth asking up front is use-case (email / blog / docs / creative)
because it changes which AI mode loads first, and solo-vs-team because it's a pricing fork, not a content
fork. Everything else should be skipped in favor of getting the user's *own text* into the tool within the
first screen — the "do the real thing once" lever matters more here than anywhere else, because most AI
products (per the corpus) never let the user touch the real mechanic before asking for an account.

### The question set

| Question | Why it's here | Wording | Presentation |
|---|---|---|---|
| What do you write most? | personalizes plan (a) — selects which AI mode/template loads on first use | "What are you mostly writing?" (Emails / Blog & content / Docs & reports / Creative — pick one or more) | multi-select cards |
| What slows you down? | makes problem salient (b) — feeds the agitate beat and the plan-reveal copy | "What's the most annoying part of writing for you?" (Starting from a blank page / Editing takes forever / Not sure my tone lands / Grammar & polish) | single-select list |
| Solo or team? | feeds pricing/segmentation (d) — routes to individual vs. team pricing track | "Are you writing mostly on your own, or with a team?" | single-select, placed right before the first paid touchpoint, not day one |

Cut: no name field (a writing tool doesn't need a greeting relationship the way a coach app does — the
product speaks through the user's own draft, not a mascot); no demographic questions (nothing downstream
changes because of age/role); no commitment/effort slider (there's no daily-habit mechanic to prime a
reminder for). Per the Selection rule and the "AI apps personalize least" data point, this question set is
deliberately the thinnest of the three — the activation moment (pasting or writing real text and seeing a
real AI edit) does the personalizing that a quiz would otherwise try to fake.

### The paywall
- **Model:** freemium, contextual/metered — no day-one paywall at all. The free tier is real and usable
  (a capped number of AI generations/edits per day); the upgrade prompt triggers in-context, at the moment
  a user hits the cap or taps a Pro-only mode (tone rewrite, long-form, team-shared docs) — the paywall
  shows up as the answer to a need the user just expressed, not a wall on day one. This is the "sometimes
  the best paywall is removing the paywall screen" lever applied to freemium: the *cap itself* is the
  monetization moment, not a screen.
- **Plans (individual track):** Pro Annual $96/yr (≈$8/mo) — default, badged **"Most Popular"** · Pro
  Monthly $12/mo — anchor. **(team track, reached via the solo/team answer):** Team plan priced per seat,
  routed to a separate self-serve or sales-assisted page — kept off the individual paywall entirely so the
  two buyers never see a price that isn't theirs.
- **Trial:** none needed — freemium *is* the trial. If a short Pro trial is added later to accelerate
  upgrade, gate it behind actual usage (e.g., "you've hit your daily limit 3 days running — try Pro free
  for 3 days") rather than offering it cold on install.
- **Framing:** value framing over feature framing — sell "write like this" (show a real before/after of
  the user's *own* pasted text, Grammarly-teardown style) rather than a bullet list of Pro features; a
  quiz-driven or usage-driven tailored plan nudge is the same mechanism Grammarly's teardown credits with
  a directional ~20% upgrade lift — treat that number as a hypothesis, not a target.
- **CTA:** "Unlock Pro" (contextual, at the cap) · secondary: "Not now, I'll wait" (never confirmshaming).
- **Flagged-but-not-used:** a hard day-one paywall would contradict the stated goal (activation before
  upgrade) and the corpus's own caution that AI-chat-shaped products do worst when a heavy flow gets
  between the user and the first prompt — skip it even though it's available as a lever for other apps.

---

## App C — Habit-builder

**Interview (pre-answered):** transformation = someone who wants habits but doesn't stick → someone who
reliably shows up daily; buyer = user (solo consumer); monetization = hard-paywall subscription (no
trial); conversion goal = paid conversion; one belief needed = "this app's accountability system is
different from what I've already failed with, and committing financially today is part of how it works."

### Strategy
Core desire: identity as a consistent person — the streak is really a stand-in for "I am someone who
follows through," not attachment to any one specific habit. Problem to make salient: every prior
habit-tracking attempt died the same way — no real accountability, a broken streak that felt like failure
so the user quit rather than restarted. Future-self frame: the 100-day-streak version of themselves, proof
of reliability they can point to. Data worth collecting: which habits, why past attempts broke, and daily
commitment level — each must feed directly into the plan reveal, because with a hard paywall and no trial,
the personalized plan (not a taste of the product) is the only thing standing between "problem felt" and
"pay now," so it has to feel unmistakably earned and specific before the price appears.

### The question set

| Question | Why it's here | Wording | Presentation |
|---|---|---|---|
| Name | identity anchor — used in every streak/check-in message going forward | "What should I call you?" | single free-text, mascot-voiced |
| Which habits? | personalizes plan (a) — real goals are plural, same mechanism as Headspace's multi-goal test | "What do you want to build a daily habit around?" (Exercise / Reading / Meditation / Drinking water / Sleep / Other — pick all that apply) | multi-select cards |
| What's broken your streaks before? | makes problem salient (b) — names the failure pattern the app is positioned to fix | "What's usually killed your habits before?" (I forget / I lose motivation after a few days / No one holds me accountable / Life gets busy) | single-select list, non-shaming labels |
| How many habits at once? | personalizes plan (a) + primes permission (c) — sets the plan's scope and leads into the reminder ask | "How many habits do you want to focus on right now?" (Just 1 / 2–3 / As many as I can) | discrete chips |
| Reminder time | primes permission (c) — commitment-to-permission bridge before the OS prompt | "When should I remind you to check in?" | time picker, followed immediately by a custom pre-permission screen |
| Pick your companion/icon | ownership before the ask — IKEA-effect authorship, softens a hard paywall that follows almost immediately | "Choose a companion to keep you on track." | visual picker (character/icon cards), never a text list |

### The paywall
- **Model:** hard paywall — access is gated immediately after the personalized-plan reveal, no free use of
  the core loop first. This is the highest-conversion-pressure, highest-risk model in the catalog: Filip's
  documented position (in `dark-patterns.md`) is that hard paywalls visibly correlate with worse ASO and
  product metrics, and a share of users churn on sight of the wall — that tradeoff is inherent to the
  brief (paid-conversion is the explicit KPI here), not a mistake, but it should be named, not hidden.
- **Plans:** Annual $39.99/yr (≈$0.77/wk) — default, badged **"Most Popular"** · Monthly $6.99/mo —
  anchor · a lifetime tier hidden behind "see all plans."
- **Trial:** none, per the brief — but recommend pairing the hard wall with a **money-back / no-questions
  refund window** (e.g., 3 days) rather than nothing at all, since some of the risk-reduction lever
  (Blinkist's "how your trial works" mechanism) can be reused as "how your refund works" even without a
  trial structure.
- **Framing:** value framing on the plan-reveal screen immediately before price (the streak/future-self
  image the user just built, echoed back); social proof; weekly-equivalent price anchoring next to the
  annual price.
- **CTA:** "Start my streak" · secondary: "Not now" (never confirmshaming).
- **Flagged-but-not-used, explicitly available given the brief:** an escalating exit-discount ladder on
  dismissal (the Yoni Smolyar "Brainrot" pattern — close once for 50% off, close again for 80% off) is the
  single highest-converting lever available for exactly this app shape (hard paywall + solo consumer +
  paid-conversion KPI), and the corpus shows it paired with polished, mascot-driven onboarding much like
  this one. **Risk, stated plainly:** high — Apple's 2026 policy update rejects the "offer shown after the
  main paywall is closed" pattern outright (App Store non-shippable, not just a trust judgment call), and
  even where shippable it trains users to distrust the first price and erodes long-run retention per
  Mobbin's own paywall researcher. If used at all, cap it at a single non-repeating offer, not a chain, and
  verify current App Store guideline status before shipping on iOS.

---

## Cross-app note (not part of any single app's spec)
The three question sets converge on the same *categories* (goal/intent, pain/problem, commitment/effort)
because those categories are close to universal for consumer apps with a plan-reveal — but the *count*,
*wording*, and *what gets cut* differ by monetization model and KPI: the trial-start app (A) keeps a
full six-question set because its trial ask benefits from a fully personalized plan; the freemium
activation app (B) cuts to three questions and defers personalization to real usage, per the "AI apps
personalize least" dataset finding; the hard-paywall app (C) keeps six questions *and* adds an
ownership/preference question (companion picker) specifically because it has no trial to soften the ask,
so the plan reveal has to carry the entire trust burden alone.
