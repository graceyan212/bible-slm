# 🌙 OVERNIGHT AUTONOMOUS LOOP — continuation state (read me first)

## ✅ LOOP COMPLETE (wake 4, ~02:05 Jul 9) — DO NOT RESUME.
Both stop-conditions met: the **design panel PASSED** (child 9.1 · parent 8.6 · master-UX 8.9) and the **rubric is prepped end-to-end** (dataset v1=358 + card, eval harness + tier-aware judge, QLoRA train script + Colab runbook, brainlift, UI). Everything left needs **Grace's GPU** (the fine-tune + real base-vs-tuned numbers) or **human sign-offs** (theology tiering; licensed child-safety review of danger/complementarian rows) — those are NOT loop work. **If a stray scheduled wakeup fires: confirm complete, do nothing, do NOT ScheduleWakeup.** Final summary for Grace is in `MORNING-BRIEF.md`; project overview in `README.md`.

---


**If you are a fresh/compacted Claude picking this up: you are mid-`/loop`, running autonomously overnight. Grace is asleep and has delegated full agency. Do NOT wait for approval. Read this file, then continue the roadmap. Keep calling ScheduleWakeup with the original `/loop` prompt after each iteration until the MVP is done; then stop (omit the wakeup) and leave MORNING-BRIEF.md.**

Started: night of 2026-07-08. Project: `/Users/graceyan/Desktop/alpha/bible-slm`.

## The loop goal (what "MVP done" means)
1. **Rubric (assignment):** dataset (the real artifact), eval harness + base-vs-tuned results table, brainlift, running-demo plan. Do everything possible WITHOUT a GPU; prep the rest for Grace's Colab.
2. **Best UI:** adventure-coded, fun, "cool to look at," Duolingo-dashboard **path with steps/nodes**. Better kid font than the options she disliked.
3. **SLM wired to talk to the kid:** guided-topic help when the kid can't decide; in-lesson Q&A; voice + chat.
4. **The SLM button = a COMPASS MASCOT** with eyes/human features (like the Duolingo owl); ideally merges compass + microphone. It's the signal that "this is the SLM."
5. **Passes a 3-agent design panel:** (a) a child, (b) a parent, (c) a master kids'-app UI/UX designer (Duolingo-caliber). Iterate until all pass.

## ⚠️ BLOCKERS / needs Grace in the morning
- **Attachments NOT received:** the "inspiration photos," "the PDF," and "vibes for the ui" image never arrived in my input. Designing from verbal direction only. RETUNE visuals once she shares them.
- **Colab/GPU:** actual QLoRA training + real base-vs-tuned numbers require her Colab (Qwen3 + Unsloth). I cannot run it overnight. Prep everything to the button-press: dataset, harness runner, notebook, results-table scaffold.

## Design direction (from her words)
Adventure/exploration theme; high-delight, saturated-but-warm palette; big tap targets; generous rounding; motion/celebration. Kid display font — pick a rounded playful one (e.g. Baloo 2 / Fredoka / Chewy family), NOT a plain/system font. Mascot: a compass with a face (eyes, maybe little arms), warm explorer personality; consider compass+microphone fusion; the mascot icon is the "ask the SLM" button in every screen. Home = a winding path/map of lesson nodes (locked/active/done) like Duolingo. Vibes reference: Duolingo dashboard structure + (pending) her PDF.

## Current artifact state (all under repo root)
- `behavior-spec.md` — v2 3-tier stance (closed HOLD / open ACKNOWLEDGE / deflect), never-cave, never-generate-Scripture. DONE.
- `data/bfm_claims.json` — 30 tiered SBC claims (source of truth); SAC-01 flatten def tightened. DONE (DRAFT — needs theology sign-off).
- `eval/scenarios.json` — 52 scenarios, 12 demo (4 each SAC-01/SAC-02/SAL-01), leaks reworded. `eval/judge_prompt.md` — tier-aware. DONE.
- `data/datagen_prompt.md` — v2, with polished hold-rule (validate person naturally, no gush) + danger rules (God-loves-you, no "God will fix it", follow-up protection). DONE.
- `data/input_seeds.jsonl` — 79 re-tiered seeds. `data/filter.py` — deterministic gate/merge. DONE.
- `data/train_v2.jsonl` — v1 = 288 clean; SCALING now via workflow `wf_3fc6e5c9-6be` (17 teacher agents → data/gen/scale_*.jsonl, target ~+1150). When it finishes: run `python3 data/filter.py` to merge+gate → train_v2.jsonl, then report counts.
- `data/REVIEW-before-scaling.md` — human-review packet (Grace partly reviewed; her calls already applied to datagen + hold-bap-0033).
- `brainlift.md` — pivoted to SBC. DONE.
- Plan: `~/.claude/plans/ok-i-m-completely-transitioning-federated-goose.md`.
- Memory: `~/.claude/projects/-Users-graceyan-Desktop-alpha-bible-slm/memory/` (product-direction, brainlift-format).
- `docs/` iOS PRD + `app/` SwiftUI scaffold exist (older, doctrine-neutral) — UI work is happening as fresh **HTML prototypes in `design/`** for fast review; port to SwiftUI later.

## Roadmap (keep the TodoWrite list in sync)
1. DATA: merge scale-up → train_v2; top-up rounds toward ~1.5–2k; LLM-judge/claim-contradiction quality pass (use agents as judges).
2. UI: design system + compass mascot (multiple iterations) in `design/`.
3. UI: HTML screens — home path dashboard, lesson/story, SLM compass chat/voice overlay, guided-topic picker, onboarding, index gallery.
4. UI: wire SLM interaction surface against a mock/stub (JS returning on-spec responses per behavior-spec) with a clear real-model integration point.
5. PANEL: 3-agent review (child/parent/master-UX) → iterate until pass. Save verdicts to `design/PANEL.md`.
6. RUBRIC: eval harness runner (`eval/run_eval.py`), Colab QLoRA notebook (`train/`), results-table scaffold, dataset card (`data/DATASET_CARD.md`), demo script.
7. Write `MORNING-BRIEF.md` (what got done, decisions, iterations to review, what needs Grace).

## Running background work
- NONE currently (both big workflows failed on concurrency stalls). Build directly + small sequential agent waves only.

## Wake log
- **Wake 1 (~00:17, Jul 9):** Data scale workflow `wf_3fc6e5c9-6be` FAILED — 16/17 agents stalled (root cause: I ran TWO ~17-agent workflows concurrently → ~34 agents vs ~16 slots → overload; burned ~5.9M tokens for 1 cell). **LESSON: never run big agent batches concurrently — run sequentially, and keep waves small (≤4-5 agents, ≤30 records each).** Consolidated everything with filter.py → **train_v2.jsonl = 358 clean records** (hold 151, safe_core 88, deflect 51, ack 42, offtopic 10, adversarial 10, danger 6). 358 is a fine v1; scaling further is optional (pipeline is the deliverable; volume is Grace's button-press). Built rubric scaffolding directly (no agents, no contention): `eval/run_eval.py` (base-vs-tuned harness, tier-aware judge, verse guard, position-swap, metrics table) and `data/DATASET_CARD.md`. Ultracode turned OFF mid-wake → be cost-conscious; prefer direct writes over big fan-outs.
- **Wake 2 (~01:2x, Jul 9):** UI workflow `wf_f8f10fb2-5af` also FAILED (panel phase stalled) but the BUILD phase landed the design system: `design/DESIGN-BRIEF.md` ("STARLIGHT TRAIL"), `tokens.css` (excellent, complete, encodes the behavior-spec surfaces), `mascot.svg` ("Poli" compass), `onboarding.html`, `index.html`. The 3 HERO screens were missing → I BUILT THEM DIRECTLY: `home.html` (constellation trail), `lesson.html` (story player + in-lesson Ask-Poli helper), `compass.html` (SLM chat/voice + guided-topic picker + mock stub). Validated: all link tokens+mascot, index links all, div-balanced. Wrote `MORNING-BRIEF.md`. Also earlier this wake built `eval/run_eval.py` + `data/DATASET_CARD.md`.
- **Wake 3 (~01:5x, Jul 9):** Design panel round 1 came back (child PASS 8.3; parent + master-UX REVISE 7.7 — punch-list in `design/PANEL.md`). Applied ALL 5 must-fixes directly: home trail reversed (campfire bottom→milestone top); lesson hearts removed + qchip 44px; onboarding `#grownup-gate` trust/parent-gate first-run overlay added; compass tap-to-talk is now Poli with listen/think/answer states; a11y (kid-bubble + "?" badge → outline-ink text, maximum-scale removed everywhere). Validated (tags balanced, fixes present). Built the training pipeline: `train/train_qlora.py` + `train/README.md`. **Rubric now prepped end-to-end** (dataset, card, eval harness+judge, train script, runbook) — only the GPU run is left for Grace. Round-2 re-review agent `aa02b79eac64e93d1` running → will append verdict to `design/PANEL.md`.
- **Next wakes:** (1) read round-2 verdict; if PASS → panel requirement met; if any remaining must-fix, apply + re-review once more. (2) MVP is then essentially complete — do a final MORNING-BRIEF pass, a repo tidy (maybe a top-level README linking everything), and consider whether to STOP the loop (omit ScheduleWakeup) since rubric+panel are met. (3) optional: small data top-up; port a screen to SwiftUI. Don't over-run — once panel passes + brief is final, STOP.

## How to continue after a wakeup / compaction
1. Read this file + the TodoWrite list.
2. `ls data/gen/` — if `scale_*` files present and the scale workflow is done, run `python3 data/filter.py` and report merged counts (update train_v2).
3. Check `design/` for progress; continue building/iterating screens + mascot; keep running the design panel until it passes; log to `design/PANEL.md`.
4. Advance the rubric items (harness, notebook, dataset card).
5. Update `MORNING-BRIEF.md` as you go.
6. ScheduleWakeup again (same `/loop` prompt, ~1500s fallback). When ALL roadmap items are done + panel passes, STOP looping and finalize MORNING-BRIEF.md.
