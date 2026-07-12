# Morning Brief — True North overnight build (night of 2026-07-11)

Good morning! Everything is integrated, building, verified in the simulator, and
pushed to `onboarding-architect-skill` (synced 0/0, tip `f05250b`). Core tests 20/0.
The phone was off, so this was verified in the iOS **simulator only** — the physical-device
white-screen is still open (see bottom).

## What shipped tonight (all 5 tabs done + cohesive)
1. **Map** — now a vertical **scrollable** treasure map. The background was extended to a
   taller hand-composited canvas (656×5900, `design/build_tall_map.py`, no API — feathered
   crops of the original art, same sepia-parchment aesthetic). All **12 story stops** ride a
   winding rope trail, evenly spaced, ending near the compass/ship/treasure-chest destination.
2. **Stories** — a new **Story Library**: a 2-column shelf of all 12 covers in curriculum
   order with done/active/locked states. Muted parchment background so the colorful covers pop.
3. **Ask Poli** — mascot + **voice input** (mic) + text field + "Pick a star" suggestion chips
   that model the 3-tier stance (hold / acknowledge / deflect-to-parent).
4. **Treasures** — reframed as **"Your Night Sky"**: stars = the cumulative **number of days**
   you've explored (one per visit, **never lost — deliberately NOT a streak**, grace-not-guilt),
   plus a treasure/badge shelf. "Come back any day to light another star — you'll never lose one."
5. **Grown-ups** — Family Dashboard: explorer progress, Family Bible (NIrV), How Poli Teaches
   (3-tier), Safe & Private. Numbers now consistent with Treasures (**12 days explored · 3 of 8
   treasures**; the old "3-day streak" chip is gone).

Nav is the 5-item wood plank on the map (parchment bar elsewhere) with the raised center Poli.

## The 12 stories (one shared `StoryCatalog` drives BOTH map + library)
Creation · The Red Sea · Jesus & the Children · The Promise · Jonah & the Big Fish ·
The First Christmas · Daniel & the Lions · The Good Shepherd · David & Goliath ·
The First Easter · The Father Who Ran (Prodigal) · Zacchaeus.
Content + per-page art came from the concurrent story-gen effort (branch `app-work`,
judge-vetted "12/12 PASS"); each story's own art renders in the reader (verified David & Goliath,
Easter, Zacchaeus, Jonah, Prodigal). Adding a story later = one line in `StoryCatalog.all`.

## ⚠️ Please review before shipping (I did NOT change these autonomously)
1. **Onboarding social-proof step is fabricated.** It shows a "4.8" rating + two invented
   testimonials ("Rachel, mom of two"; "David, dad"). For an unreleased app that's the same kind
   of overclaim as the pastor line I removed — but deleting the step reshapes the onboarding
   Step enum/flow/deep-links, so I left it for you. Decide: remove, or reframe as honest
   "early access." (File: `OnboardingView.swift`, `socialStep`.)
2. **Story `verse` fields are PLACEHOLDERS.** Per behavior-spec, exact verses must come from the
   family's **licensed NIrV**, never model-generated. The JSON verse text must be verified/licensed
   before ship. I left narrative retells untouched and did not fix verse text.
3. **Minor cohesion nit:** the Ask Poli screen title uses the system bold font rather than the
   IM Fell display used on every other tab's title ("Your Night Sky", "Story Library", "Family
   Dashboard"). Low-risk one-liner in `CompassView.swift` if you want it consistent — I left it
   because that file carries the new voice logic and I didn't want to destabilize it overnight.

## Still open
- **Physical-device white screen** — DEFERRED. Clean Release install still white; the CLI can't
  capture the crash (devicectl console hangs, no crash logs sync). Needs an Xcode **Run** to the
  device to read the actual crash. Simulator is 100% fine.

## What I did to get here (audit trail)
Integrated 3 parallel worktree agents (Grown-ups, Treasures, Map+Library) + a 4th for the
12-story fold-in, each verified in the sim and pushed by explicit paths. Fixed the "Reviewed by
pastors" overclaim in all 3 onboarding spots → consistent "Built on / aligned with the Baptist
Faith & Message (2000)". Removed several stray `BibleStory N.xcodeproj` dirs left by concurrent
xcodegen runs. Commits: 08c73ff → b49dd67 → 3f6814c → 388fbc0 → 26d1b5c → f05250b.

_(Supersedes the prior 2026-07-08→09 SLM-training brief; that work is complete — see memory.)_
