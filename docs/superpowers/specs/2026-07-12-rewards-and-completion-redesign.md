# Rewards & Completion Redesign

**Date:** 2026-07-12
**Status:** Design — approved shape, pending spec review → implementation plan
**Scope:** The Treasures page, the reward economy behind it, and the post-story completion screen.

## Problem

The reward system today is a pretty mockup fed by fake data, with three overlapping "currencies" and only one of them real:

| Thing | Meaning | Real? |
|---|---|---|
| Stars (`NightsProgress`) | nights a story was *completed* — monotonic | ✅ persisted |
| Stars (`TreasuresView` sky) | *days visited* — a different meaning, same word | ❌ static JSON (`daysExplored: 12`) |
| Gems | nothing earns them, nothing spends them | ❌ static (`7`) |
| Treasures | story completions + milestones | ❌ hardcoded `earned:`, not wired to `completedStoryIDs` |

So: "star" means two contradictory things, gems reward nothing, the treasure grid's earned/locked state is hand-authored rather than derived from real progress, and the post-story screen crams the celebration, the collectible, the day tally, a milestone, and the gospel point into one scroll — where the gospel point (the actual payload) drowns.

## Principles (unchanged brand commitments)

- **Grace, not guilt.** Progress is only ever *gained*, never lost. No streaks, no resets, nothing turns red, no loss-aversion. (Grounded in `docs/research/06`: consecutive-day streaks are flagged as manipulative for children.)
- **Collection over score.** The joy is a growing shelf of meaningful keepsakes, not a rising number to beat. Best-fit, lowest-risk reward mechanic for ages 7–9.
- **Formation is the destination.** The treasure is the doorway; the Christ connection is the room you walk into. Rewards must not upstage meaning.
- **Simplicity for a 7-year-old.** The child should hold at most a couple of ideas at once.

## The model

The child sees **one collection**, **one plain number**, and **moments that celebrate** — deliberately kept minimal.

### 1. The Treasure Chest — the single hero visual

- A shelf/grid of **story relics: one unique keepsake per story**, earned when the child *finishes* the story.
- Relics are **concrete, iconic objects** (memory hooks for the lesson), not abstract emblems. E.g. the manger, the smooth stone, the great fish, Moses' staff, the father's ring.
- **Only earned relics are shown.** No locked slots, no mystery silhouettes, no "what you're missing." The shelf simply grows.
- **Empty state** = a warm invitation ("Your treasures will appear here as you explore"), never shame.
- **Counter = "N treasures"** — a thing you *have*. **No denominator** (no "7 of 12"): a denominator would re-expose the missing ones and reintroduce the completionist pressure that hiding locked treasures exists to avoid.

### 2. Days exploring — a plain supporting counter

- Counts **distinct days the child explored a story** — defined as *opened a story and spent time in it*, NOT "must finish." A tired child who stops mid-story still gets credit for showing up.
- Displayed as a **small badge** ("12 days exploring") near the chest, and optionally a home-map corner. **No dedicated visual, no metaphor** — the night-sky visualization is removed. The chest is the only thing that *looks* like a collection.
- Monotonic and per-day de-duplicated (one increment per calendar day, regardless of how many stories).

### 3. Milestones — moments, not a menu

- When relics or days cross a mark (e.g. "First Treasure," "5 Stories Explored," "A Week Exploring"), a **gentle line/animation fires** in the moment.
- Milestones are **not a browsable grid** and are **not a third thing to track** — they are *derived* from the two real signals (relic count, day count) and surface only as celebration. Nothing to hunt for.
- Celebration only — never a "don't lose it" warning.

### Why this is two things, not three

Milestones are pure functions of the relics and days. The child's actual mental model is:

- **The chest fills** when you *finish a story*.
- **The days counter ticks** when you *come back and explore*.

Milestones ride along for free as happy surprises. Two verbs, two signals, minimal load.

## What we track (data)

All signals are **real, persisted, and monotonic** — derived, not hand-authored.

- **Relics earned** ← derived from `AppEnvironment.completedStoryIDs` (already persisted). No separate earned-state store.
- **Days exploring** ← `NightsProgress`, **retitled** and its rule **relaxed from "completed" to "explored"** (opened + spent time), so it stops disagreeing with the chest. Still monotonic, still one-per-calendar-day.
- **Milestones** ← pure functions of relic-count and day-count. Nothing new stored.
- **`treasures.json`** → shrinks to **static metadata only**: relic `name`, `emblem`/art, and the `story` it belongs to. It no longer carries `earned`, `daysExplored`, or `gems`. Earned-ness is computed at read time from `completedStoryIDs`.
- **Gems** → **removed** entirely (data, pill, and all references). If a spendable currency is ever wanted (e.g. unlock a mascot outfit), that is a deliberate future feature, not leftover scaffolding.

## The post-story completion screen — two calm beats

Today everything lands on one crammed scroll (medallion + "TREASURE EARNED" + name + star badge + milestone + Christ-connection heading + Christ-connection text + reward text + button). Split it so **collecting** and **reflecting** stop competing:

**Beat 1 — "You found a treasure!"**
- The story's relic appears with a small celebration.
- The days counter ticks (if today was a new day).
- If a milestone just crossed, one gentle line.
- Short and joyful. Tap to continue.

**Beat 2 — the Christ connection**
- Spacious and calm, on its own screen — the point *lands* without competition.
- Then the actions: **Back to the map**, **Read it again**, and (once wired) **Ask Poli about this**.

Ordering the treasure *before* the meaning makes the treasure the doorway and the gospel point the destination — the formation-first core, wrapped in the collection spine.

## Open sub-choices (resolved during implementation planning; not blockers)

- **Final relic art/emblem per story** — one iconic object each. A starter mapping (to be finalized):

  | Story | Relic |
  |---|---|
  | Creation | the first light |
  | The Promise (Noah) | the ark (or the rainbow) |
  | Red Sea | Moses' staff |
  | Jesus & the Children | a small sandal |
  | Jonah | the great fish |
  | First Christmas | the manger *(not "the star" — avoids colliding with the days concept if ever revisited)* |
  | Daniel | the lion |
  | Good Shepherd | a little lamb |
  | David & Goliath | a smooth stone |
  | Easter | the rolled-away stone |
  | Prodigal Son | the father's ring |
  | Zacchaeus | a gold coin |

  New relic art follows the existing folk-art style and is generated **via the TrueFoundry gateway** (`design/generate_scenes.py`, `design/scenes.json`) — never a direct image-model key.
- **Exact milestone thresholds** and their wording.
- **"Ask Poli about this"** — ship in Beat 2 now, or defer until the Ask/Compass flow is wired end-to-end.

## Out of scope

- Spendable currency / a store.
- Streaks, leaderboards, or any comparative/social mechanic.
- Reworking the map trail itself (only the reward + completion surfaces change here).

## Verification (how we'll know it's right)

1. `swift test --package-path app/BibleStoryCore` green — including the relaxed `NightsProgress` "explored" rule and any milestone-derivation logic.
2. `xcodebuild … -destination 'platform=iOS Simulator,name=iPhone 17' build` → BUILD SUCCEEDED.
3. On device: finish a story → Beat 1 shows the correct relic, the day counter ticks once (and not again on a second finish the same day), Beat 2 shows the Christ connection with working actions → open Treasures and confirm the new relic is present, only earned relics show, the counter reads "N treasures" with no denominator, no gems, no night sky.
4. Complete a second story on the same day → days counter does **not** double-count; a new relic appears.
5. Cross a milestone threshold → the celebration line fires once, in the moment; nothing new appears as a browsable item.
