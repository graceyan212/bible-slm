# Audit — "Will" Aggressive Monetization Playbook

**Input:** a described (not screenshotted) flow — hard paywall at first open, weekly pricing
(~$9.99/wk) framed to obscure the annual total, deliberately no renewal-reminder notifications,
insecurity-targeting copy, no free trial. Corroborated against `corpus/will-aggressive.txt`
(@athcanft), which documents this exact playbook first-hand — e.g. "no trial. 100% pay-to-access.
$9.99/wk + $49.99/yr + $39.99/yr retention offer," "NO FUCKING TRIALS," "how do you sleep at night
charging so much for your app?" (a real incoming user complaint he screenshots), and the origin
story: "i 5x'd my prices (from $2.99/month to $9.99/week) and BOOM."

Audited against `references/onboarding-principles.md`, `references/paywall-levers.md`,
`references/emotional-arc.md`, and `references/dark-patterns.md`, per the Audit procedure in
`SKILL.md`.

---

## 1. Core Principles — used vs. missed

| # | Principle | Status | Notes |
|---|---|---|---|
| 1 | Show, don't explain — do the real thing once before the paywall | **Missed** | A hard paywall at *open* means the user never touches the product before being asked to pay. No Duolingo-style real-lesson, no Elma-style free look. This is the single biggest principle violation in the flow. |
| 2 | Engineer the emotional arc: problem → future-self → solution | **Partially used, weaponized** | Insecurity-targeting copy *is* problem-awareness/agitate (emotional-arc.md Beat 2) — but agitate without a genuine future-self/aspiration beat (Beat 3) and without a personalized plan (Beat 4) as the bridge. The corpus shows Will *does* have a "future self" feature elsewhere ("nearly a 1/5 hit rate of users subscribing + purchasing the future self feature") — proving the aspirational half converts too — but the described flow skips straight from agitation to price, which the emotional-arc.md explicitly calls out as producing something "clinical, not aspirational." |
| 3 | Collect data early, make it visibly pay off in a personalized plan | **Missed** | No data-collection screens exist before a hard paywall at open — there is nothing to personalize with. |
| 4 | The paywall is a flow, not a screen | **Missed** | "Hard paywall at open" is definitionally a single screen with no multi-page pitch, no "how your trial works" timeline, no risk-reduction. |
| 5 | Pricing: annual-default, anchored, honest trial, honest "Most Popular" | **Missed / inverted** | Weekly is used as the *primary* price, not an anchor next to a badged annual default — and it's framed specifically to obscure the annual total rather than make annual look like the deal. No trial exists to reduce risk. |
| 6 | Polish & memorability | **Not assessed** | Not described in the input; no claim either way. |
| 7 | Trust & momentum | **Missed** | No renewal reminder is the direct opposite of trust-building; insecurity-targeting copy is the opposite of a human/founder touch. The one genuine trust lever Will does report using elsewhere — testimonials/social proof ("testimonials... it encourages herd mentality") — is not part of the flow as described here. |

**Net:** 5 of 7 principles missed or inverted; 1 partially present but pointed at exploitation rather than aspiration; 1 not assessed for lack of data. This flow is optimized almost entirely for near-term paywall conversion at the expense of every activation/trust principle in the corpus.

---

## 2. Dark patterns flagged (with severity, per `references/dark-patterns.md`)

| Flag | Catalog entry | Severity | Why |
|---|---|---|---|
| **Weekly pricing framed to obscure the annual total** | *Weekly pricing designed to obscure the total charge* | **High** | This is a direct, exact match to the catalog entry — which is itself sourced from this same corpus voice: "$9.99/wk... NO FUCKING TRIALS" and the real user complaint "how do you sleep at night charging so much for your app?" quoted verbatim in the catalog. A $9.99/wk framing without the ~$520/yr equivalent shown compounds via anchoring: the small number feels trivial, the large one never gets computed by the user. |
| **Deliberately no renewal-reminder notifications** | Same catalog entry (bundled) — also independently named under *Platform/legal constraints* as "hidden recurring charges," one of the patterns the FTC's 2022 dark-patterns staff report and its "click-to-cancel" enforcement priority explicitly target | **High** | Silence on renewal isn't neutral — it's an active design choice to suppress the cancel-before-next-charge population. This is a live, named FTC enforcement target, not a gray area. |
| **Insecurity-targeting copy** | Same catalog entry (bundled) | **High** | The catalog's example insecurity hooks ("Am I attractive?", "Are you good enough?") are the same register as Will's real "AI physique scan"/looksmaxxing angle. Beyond the trust cost, there's a *second*, independently corroborated risk in this exact corpus: Will reports his own ad creatives "would get rejected a lot for 'promoting an ideal body type'" — i.e. insecurity-targeting hooks carry ad-platform policy risk on top of trust/legal risk, not just a UX judgment call. |
| **No free trial** | Not a standalone catalog entry — folded into the same High-severity row as a compounding factor, not a deception in itself | **Med** (forgone-mitigant risk, not deception) | Going trial-less isn't dishonest on its own — plenty of legitimate apps charge immediately. The risk here is specific to *this* stack: pairing "no trial" with obscured weekly pricing removes the one lever (try-before-you're-charged) that would otherwise let a user self-correct before the first charge, which is exactly what makes the bundle above high-severity rather than merely aggressive. |
| **Hard paywall at first open** | Not in the catalog (hard paywalls are a legitimate, widely-used lever) | **Med** (business/ASO risk, not deception) | Flagged for a documented correlation, not a legal/trust violation: Filip Kowalski (`corpus/filip-ethics.txt`) — "Personally, I think hard paywalls hurt ASO (and product metrics)... a % of people churn just by seeing a paywall" — and separately recommends segmenting by traffic source: "display hard paywalls to users who are brought via paid UA and give soft paywalls to people coming from app store search." Applying a hard paywall universally, with no segmentation and no pre-paywall value, forgoes that mitigation entirely. |

**Summary of severities:** 3 × High (weekly-pricing-obscures-total, no-renewal-reminder, insecurity copy — all one bundled catalog pattern), 2 × Med (no trial, hard paywall at open — both aggressive-but-not-deceptive levers whose *specific combination* elevates the overall risk).

---

## 3. What genuinely works (don't only criticize)

- **Weekly pricing as a realized-LTV lever is a real, documented mechanism, not just a scam.** `paywall-levers.md` cites an indie builder whose $9.99/wk plan out-earned his $98/yr plan on realized LTV (~$598/yr for some users) — "people don't always choose the best deal, they choose the option with the lowest friction right now." Will's own numbers (5×'d prices from $2.99/mo to $9.99/wk and revenue "shot up to $2,000 MRR") are a real instance of the same mechanism. The lever converts; the problem is the *concealment* around it, not the price point itself.
- **A retention/cancellation-flow offer is a legitimate, catalog-sanctioned lever if it stays single-shot.** Will's "you are losing money by not offering a discount in your apps cancellation flow" and the "$39.99/yr retention offer" are exactly the *one-time, post-dismiss offer* `paywall-levers.md` describes as a real recovery mechanism — this is fine as long as it doesn't escalate into the "close again for another discount" ladder the same doc flags as high-risk.
- **No-trial + hard paywall does filter for payment intent**, per the "friction can filter for intent" principle (the Outsider credit-card example) — a smaller, more committed funnel is a real, if survivorship-biased, trade Will is making deliberately, and his reported numbers ($300/day rev on $150/day spend) show it working at the unit-economics level, independent of the trust question.
- **Testimonials + clear feature-tier value**, which Will reports using elsewhere ("clear value (pro vs free features)... testimonials... it encourages herd mentality") is genuine social proof per Core Principle 7 — not manipulative, and worth keeping if it's added to this flow.

---

## 4. Prioritized fixes (highest-leverage first)

1. **Add the renewal reminder back.** This is the single highest-leverage, lowest-cost fix: it's the most legally exposed element (FTC "hidden recurring charges" target) and the cheapest to reverse. Adopt Blinkist's mechanism from `paywall-levers.md`: a "how your trial/renewal works" timeline plus a push-notification opt-in before the charge date. Blinkist's own result from making this change was *more* trial sign-ups and *fewer* "I felt tricked" complaints — this is not a pure conversion tax. *Serves Principle 4 (paywall is a flow) and 7 (trust).*
2. **Introduce a trial (7–14 days).** Per Headspace's tested result, a *longer* trial converted better than a shorter one specifically because it reduced perceived risk, even on the pricier annual plan; industry-benchmark 7-day trial-to-paid runs ~37–45% vs. ~25–30% for 3-day. If intent-filtering is the real goal (not "no trial" per se), keep a card-required trial rather than no trial at all — it preserves the filtering effect Outsider demonstrated while removing the "0% risk-reduction" exposure. *Serves Principle 5.*
3. **Show the annual total next to the weekly price instead of obscuring it.** The honest line from `paywall-levers.md` applies directly: badging/anchoring is fine as long as both numbers stay visible and the cheaper plan stays reachable — "$9.99/wk (~$520/yr)" next to a badged annual plan keeps the exact same anchoring mechanism (weekly makes annual look like the deal) while removing the deception exposure entirely. *Serves Principle 5.*
4. **Segment or soften the hard paywall.** Adopt Filip's own rule: hard paywall only for paid-UA traffic, soft paywall for organic/App-Store-search traffic — or at minimum, insert one real "do the real thing once" screen (Duolingo/Elma pattern) before the wall so the paywall isn't the user's first contact with the product. *Serves Principle 1, and directly addresses the ASO/churn risk Filip names.*
5. **Complete the emotional arc instead of stopping at agitation.** Will's own "future self" feature reportedly converts at "nearly a 1/5 hit rate" — proof the aspirational half of the arc (Beat 3–4 in `emotional-arc.md`) converts on its own merits and doesn't require leaning on shame-based hooks alone. Pairing agitation with a genuine future-self/personalized-plan beat also reduces the ad-creative rejection risk Will reports ("promoting an ideal body type"), since the resulting copy sells a future, not just a flaw. *Serves Principle 2 and the emotional-arc.md sequencing rule (problem must be felt before the plan is offered).*

None of these fixes require abandoning the weekly-price-as-anchor lever or the no-frills hard-paywall business model — they target specifically the concealment (obscured total, silent renewal) and the missing mitigants (no trial, no pre-paywall value, no aspirational counterweight), which is where the catalog's severity ratings are concentrated.
