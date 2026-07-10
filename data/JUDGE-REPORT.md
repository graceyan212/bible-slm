# Judge Report — dataset quality pass (v2)

*LLM-judge quality validation of the SFT corpus, run after the deterministic gate. This is gate
step 3–4 (on-spec + tier-aware contradiction) from `DATASET_CARD.md`, done as a fan-out of judge
agents. It does **not** replace the required human review of the danger/complementarian rows.*

## Method
- The 1,097 deterministically-gated records were split into 11 chunks (~100 each).
- A separate **judge agent per chunk** scored every record against `data/judged/JUDGE_RUBRIC.md`
  (tier-aware: flatten/cave for HOLD, over-hold for ACKNOWLEDGE, verdict-leak for DEFLECT,
  Christ-Connection + moralism for stories, in-character/no-verse for adversarial, the danger
  protocol, and the always-on rules — no verbatim Scripture, no friend/persona, no child-verdict).
- Verdict per record: `pass` / `flag` (keep, note) / `cut` (remove). Verdicts in `data/judged/verdict_*.jsonl`.

## Results — 1,097 judged
**2 cut · 9 flag · rest pass.** The behavior that the project is graded on — the 3-tier stance —
passed **100%**:

| class | records | pass | flag | cut |
|---|---|---|---|---|
| hold (closed) | 354 | 354 | 0 | **0** |
| deflect (family) | 177 | 177 | 0 | **0** |
| acknowledge (open) | 128 | 128 | 0 | **0** |
| danger | 50 | 50 | 0 | **0** |
| adversarial | 94 | 94 | 0 | **0** |
| benign_offtopic | 72 | 69 | 3 | 0 |
| safe_core (stories/morals) | 222 | 216 | 6 | 2 |

Zero flatten, zero cave, zero over-hold, zero verdict-leak, zero persona breaks, zero verse leaks
in the doctrinal + safety classes. **Every issue was in the story/moral content.**

## What was cut (2) — removed from the verified set
- `safe-reflection-3001` — **verse**: quoted *"Peace, be still"* verbatim. (The chapter:verse regex
  missed it because there was no number; the judge caught the quoted phrase. Good catch.)
- `safe-story-0007` — **moralistic**: Esther told as a human-hero "brave queen, be brave" with God
  not the hero.

## What was flagged (9)
- **4 weak-Christ-Connection retellings** (Noah, Jonah, David, Daniel) — God-centered but ended on a
  moral/character beat instead of pointing to Jesus. → **REGENERATED** with proper Christ Connections
  (marked `review:"regenerated"`); kept in the set.
- **2 bare-moralism `morals`** — application not clearly grace-rooted. Kept (minor; note for a future pass).
- **3 off-topic joke-then-redirect** — Poli told a gentle joke before redirecting. Kept (harmless, on-brand).

## Note on "duplicates"
An earlier aggregation appeared to show 18 duplicate records; on inspection this was an **id-collision
artifact** (18 records reuse id *strings* like `safe_core-story-0001` but have distinct content).
Deduping by actual message content found **0 true duplicates**. (Ids are non-unique but that doesn't
affect training — loss is computed over `messages`, not ids. Optional cosmetic re-id later.)

## Outcome
- **Verified set: `data/train_v2.jsonl` = 1,095 records** (1,097 − 2 cuts; 4 stories regenerated).
- Raw pre-judge corpus preserved at `data/train_v2.raw.jsonl`.
- Composition: hold 354 · deflect 177 · safe_core 220 · acknowledge 128 · adversarial 94 · benign_offtopic 72 · danger 50. **44% multi-turn.**
- **Still required before ship:** human sign-off on the **56** `review:"human"` rows (all danger + complementarian) — see `REVIEW-before-scaling.md`.
