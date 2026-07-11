# Paywall Levers

Distilled from Mobbin's study of **2,995 paywalls / 4,700+ designed by one practitioner**, a running
teardown series of individual high-revenue apps' paywalls (@cesaralvarezll), and an indie-builder pricing
thread (@alexcooldev). Use this as the knowledge base for designing or auditing any app's monetization
screen(s) — the pricing structure, the trial, the framing, and the recovery flow around it.

Two kinds of claims appear below, and they carry different weight:
- **Dataset mechanisms** (patterns observed across hundreds–thousands of paywalls) are treated as firm
  principles — they're a repeated pattern, not one company's guess.
- **Single-app vendor-reported stats** (a specific app claiming a specific %, ×, or point lift) are always
  labeled a **directional A/B hypothesis, not a law** — one team's result, in one context, at one point in
  time, often with survivorship bias in how it's reported. Treat the number as "worth testing," not
  "guaranteed."

---

## The paywall is a flow

**The paywall is a flow, not a screen — users often decide before they ever see it.** Sell the outcome
first, so that by the time the paywall appears it feels like a natural next step rather than an
interruption. *Exemplar:* Opal spent time before the paywall showing users how many years of their life
they'd get back from less screen time ("get 8 years of your life back"); trial sign-ups reportedly went
from **7% to 17%**. *Evidence:* [Mobbin, "We Studied 2,995 Paywalls" — single-app claim; **directional A/B
hypothesis, not a law**].

**Multi-page beats single-page.** Letting the pitch unfold across several screens — plan is ready, here's
what to expect, here's the emotional payoff, here's the price — gives users time to process the decision
instead of forcing them to absorb an entire pitch and a price on one screen. *Evidence:* [Mobbin, "We
Studied 2,995 Paywalls" — dataset pattern across the study: "multi-page paywalls almost always do better
than single-page paywalls," not a single-app stat].

**Reduce risk and you reduce hesitation, which converts.** Even a well-designed, well-timed paywall faces
the same silent objections: *will I forget to cancel? Am I making the right call?* Paywalls that answer
those questions directly — rather than hoping the user doesn't ask them — outperform ones that don't.
*Exemplar:* Blinkist's users were complaining about feeling tricked by free trials, so Blinkist redesigned
the paywall to show a step-by-step "how your trial works" timeline; the result was more trial sign-ups,
fewer "I felt tricked" complaints, and more push-notification opt-ins (users opting in to be reminded
before they're charged). A "**no commitment, cancel anytime**" subtitle on the paywall reliably bumps
conversion in Mobbin's dataset. This pattern is now Apple-endorsed, not just a growth trick: in early 2026
Apple began **rejecting paywalls that rely on a free-trial toggle** (deemed confusing/misleading) alongside
banning post-close offers stacked on top of the main paywall — the timeline/ramp format this principle
recommends is the compliant shape, the toggle is not. *Evidence:* [Mobbin, "We Studied 2,995 Paywalls" for
the Blinkist mechanism and the "cancel anytime" subtitle pattern; @cesaralvarezll teardown feed, 2026-05-16,
for the Apple toggle/post-close-offer ban].

**Presentation beats the offer itself.** The same underlying deal, presented with more clarity and
emphasis, can convert dramatically better — meaning most "the offer isn't good enough" problems are
actually "the offer isn't legible" problems. *Exemplar:* Tipstop kept the same offer but emphasized the
free trial, added a discount badge, and made the copy easier to understand; direct conversions reportedly
almost tripled. *Evidence:* [Mobbin, "We Studied 2,995 Paywalls" — single-app claim; **directional A/B
hypothesis, not a law**].

**The "pay ramp" — sometimes the best paywall redesign is removing the paywall screen.** Instead of
polishing a wall the user has to click through, some of the best-performing flows replace it with a single
low-friction action modeled on a platform-native pattern. *Exemplar:* Slopes replaced its paywall with one
action — "**Redeem your free week**" — styled after Apple's own redeem-a-trial pattern; trial starts
reportedly rose **+25%**. *Evidence:* [Mobbin, "We Studied 2,995 Paywalls" — single-app claim; **directional
A/B hypothesis, not a law**].

---

## Pricing architecture

**Default to the annual plan; show only two plans; hide the rest.** Ideally the base paywall defaults
users toward the annual product, because it carries the highest LTV — but a yearly-only paywall may not
fit every business model, so pair it with one other option (monthly or weekly). Show only two plans at a
time to cut cognitive load, and hide any additional tiers (3-month, lifetime, family) behind a "**see all
plans**" / "view all plans" button that opens a sheet. Keep the base paywall this simple long enough to get
a reliable read on baseline conversion before layering on further optimization. *Evidence:* [Mobbin, "We
Studied 2,995 Paywalls" — the practitioner's stated default heuristic, not a single-app stat].

**Use the monthly (or weekly) price as an anchor so annual reads as a steep discount — and badge the plan
you want chosen.** Pairing a small recurring price next to the annual price makes the annual price look
like the deal, and a "**Most Popular**" or "**Recommended**" badge on that plan adds social-proof pressure
and a default-steering nudge in one element. *Exemplars:* an AI home-design app teardown highlighted its
yearly plan with **"89% off"** directly on the paywall; the walking-rewards app WeWard marks its 12-month
option "**Most popular**" next to a struck-through weekly-equivalent price; a calorie-tracking app teardown
does the same — "Most popular / 12 months / ~~95,96 €~~ 35,90 €" next to a plain 3-month option; a
well-known period-tracking app's paywall (used by Apple itself as the reference example when explaining its
2026 toggle/post-close-offer ban) marks its **Yearly Plan "MOST POPULAR"** next to a family-plan option.
*Evidence:* [@cesaralvarezll teardown feed, 2026-07-07 (AI home-design app, "89% off"); 2026-05-17 (walking
app WeWard, "Wards" screen); teardown feed calorie-tracking app screenshot; 2026-05-16 (Apple's reference
screenshot). Individual app screenshots are illustrative of a widespread pattern, not a controlled test —
treat the specific badge copy/percentages as **examples to adapt**, not stats to cite].

**Honest line — badging is not the same as hiding.** Defaulting to annual and badging it "Most Popular" or
"Recommended" **while both prices remain visible and the cheaper plan stays reachable** is legitimate social
proof plus sensible default-steering; nothing is concealed and the user can still pick monthly. It becomes
a dark pattern the moment the badge or default is used to **hide the cheaper plan**, obscure the true
per-period cost, or slap "Most Popular" on the plan that is actually the *worst* value for the user (a
straight lie dressed as social proof). See `dark-patterns.md` for the full treatment of where this line
gets crossed in the wild.

**Weekly pricing can out-earn a "better deal" annual plan on realized LTV — but treat this as an n=1
anecdote, not a strategy.** One indie builder priced a plan at $9.99/week (~$40/month) expecting no one to
buy it, given his annual plan cost $98/year; it became his top-selling tier, and some users ended up paying
roughly **$598 over a year** — six times the annual price — because, in his words, "people don't always
choose the best deal, they choose the option with the lowest friction right now." This is the same
anchoring mechanism as "less than a coffee" framing (see Framing levers below), pushed to its most
aggressive form. It also sits in tension with the "reduce risk to build trust" principle above and with
Apple's 2026 anti-confusion enforcement — a weekly price this far from the annual price invites the same
scrutiny that produced the toggle ban. *Evidence:* [@alexcooldev, 2026-07-10 — single builder, single app;
**directional A/B hypothesis, not a law**, and worth weighing against the trust cost of a plan that most
users will regret].

---

## Trial design

**A longer trial can convert better than a shorter one, because it feels less risky, not because it's a
smaller ask.** The intuitive move — shorten the trial to get to revenue faster — can lose to simply giving
users more runway to feel safe committing. *Exemplar:* Headspace tested 7-day, 14-day, and 30-day free
trials; the winning variant was a **14-day trial on the annual plan** — even though the annual plan costs
more, the longer trial made the whole decision feel less risky. *Evidence:* [Mobbin, "We Studied 2,995
Paywalls" — single-app test result; **directional A/B hypothesis, not a law**].

**Trial length changes conversion at industry-benchmark scale, not just in single-app tests.** Aggregated
subscription-analytics benchmarks put 7-day free-trial-to-paid conversion around **~37–45%**, versus roughly
**~25–30%** for a 3-day trial. Treat these as directional medians to calibrate expectations against, not as
targets your specific app is guaranteed to hit — sample composition, price point, and category all shift
the real number substantially.

**Friction can filter for intent, which can raise the conversion rate even as it shrinks the funnel.**
Removing friction doesn't uniformly help — sometimes adding a small amount of friction filters out users who
were never going to pay, leaving a smaller but much more committed group. *Exemplar:* Outsider required a
credit card to start its free trial; sign-ups dropped by more than half, but the trial-to-paid conversion
rate reportedly rose **5×**, more than doubling total paying customers. Treat this specific multiple with
extra caution: **this kind of headline lift is typically measured at a single snapshot (e.g., Day 35) and
is survivorship-biased** — the users who convert under higher friction are a self-selected group, and
long-run (roughly 1-year) retention between the friction and no-friction cohorts often ends up close to
equal, which undercuts the "5× better business" read of the raw number. A related move: Moonly offered its
free trial *only* on the annual plan, pushing the same filtering effect through pricing architecture instead
of a card requirement. *Evidence:* [Mobbin, "We Studied 2,995 Paywalls" — single-app claim; **directional
A/B hypothesis, not a law, and specifically Day-35/survivorship-biased**].

---

## Framing levers

**Social proof.** Real user reviews and a visible star rating lend credibility and authority to the ask —
Mobbin's dataset repeatedly finds this among the most common high-performing paywall elements, and a full
dedicated proof page (rather than a token badge) is a stronger version of the same lever. *Exemplar:*
Timely built a full proof page of reviews and accolades ahead of its pricing. *Evidence:* [Mobbin, "We
Studied 2,995 Paywalls"].

**Value framing.** The strongest paywall copy doesn't describe the product, it describes the *future* the
user is buying — "selling different futures" rather than selling features. *Evidence:* [Mobbin, "We Studied
2,995 Paywalls"].

**Price anchoring.** Breaking an annual or monthly price down into a small weekly (or daily) figure, or
comparing it to something the user already spends money on without a second thought, makes the price feel
smaller than the same number presented as a lump sum. *Exemplars:* Tide breaks its subscription price down
into a weekly amount; another app compares its price to something people already pay for, like a daily
coffee or a therapy session ("less than a coffee"). *Evidence:* [Mobbin, "We Studied 2,995 Paywalls"].

---

## Recovery (exit offers)

**A one-time, post-dismiss offer can recover revenue that would otherwise be lost outright.** When a user
closes the paywall without converting, a single, time-boxed offer shown at that moment — not stacked
repeatedly — can win back a meaningful share of that traffic before it's gone.

**Prefer a longer trial over a discount as the recovery offer.** A longer trial extension reduces risk
(the same lever that works on the primary paywall) without training users to wait out your price, and it
preserves the trust that discounting erodes. Reserve discounting itself for genuine calendar events (e.g.,
Black Friday/Cyber Monday) rather than making it the default recovery move. *Evidence:* [Mobbin, "We
Studied 2,995 Paywalls" — practitioner's stated preference and reasoning, not a single-app stat].

**The tension to name explicitly: escalating exit discounts convert hard, and are high-risk.** A
recurring pattern in individual paywall teardowns is an *escalating* discount ladder on close — close once,
get 50% off; close again, get another discount on top (in some teardowns, 80% off). *Exemplars:* one
teardown app closes to 50% off, then 50% off again on a second close; a second app (built by indie builder
@YoniSmolyar, "Brainrot") escalates from a hard paywall to a 50% discount on first close, then 80% on a
second close; a weight-tracking app pairs this with a **spin-the-wheel "you won a discount"** mechanic
landing on "84% OFF FOREVER." These convert at the moment of the ask, but Mobbin's own paywall researcher is
explicitly skeptical of them: this is the exact toolkit used in drop-shipping/e-commerce funnels, everyone
is now copying it so its novelty (and trust benefit) is decaying, and it optimizes for near-term revenue at
the expense of long-term trust and retention — the opposite of what the "Optimize for LTV" principle below
argues for. The full ethical/dark-pattern treatment of escalating discounts and spin-wheel mechanics lives
in `dark-patterns.md`; here, the takeaway is narrower: **a single, honest, non-repeating exit offer is a
lever; an escalating ladder is a different (riskier) lever, not a stronger version of the same one.**
*Evidence:* [@cesaralvarezll teardown feed — multiple individual apps, escalating-discount and
spin-the-wheel patterns; Mobbin, "We Studied 2,995 Paywalls" for the researcher's own skepticism and the
"everyone's doing it now" erosion point. Single-app patterns; **directional, not evidence any one of these
is a durable long-term strategy**].

---

## Optimize for LTV not signups

**The north star is revenue per paywall view and first-renewal retention — not trial-starts.** Trial-starts
and raw sign-up counts are the easiest numbers to move and the easiest to be misled by; a tactic that spikes
trial-starts while quietly increasing refunds, chargebacks, or early churn is a net loss dressed as a win.
Track revenue per paywall view alongside what happens at the *first* renewal — the point where the honeymoon
ends and the churn cliff actually shows up — as the metrics that matter more than top-of-funnel conversion.
*Evidence:* [Mobbin, "We Studied 2,995 Paywalls" — the researcher's explicit framing: "the metrics that I
wish more founders really cared about are retention and LTV... maybe the question isn't how do I get people
to pay, it's how do I create something worth paying for"].

**There is no universal best paywall — only better experiments, and radical design tests move the needle
most.** Incremental copy tweaks matter less than testing structurally different paywall *formats* against
each other: a video paywall that shows the app in action, a bullet-list paywall, a comparison table, a
trial-timeline paywall, a long-form paywall. Running genuinely different designs against each other, rather
than only A/B-testing button copy on one fixed layout, is what tends to produce the breakthroughs.
*Evidence:* [Mobbin, "We Studied 2,995 Paywalls" — practitioner's stated methodology, learned from and
attributed to the Superwall team; dataset-level guidance, not a single-app stat].
