# Bible-SLM — Master Roadmap (reconciled)

*Single source of truth for what's done and what's next. Reconciles the two approved plans:*
- **Track M (Model/Data/Eval/Design)** — the overnight `/loop` plan: [`~/.claude/plans/ok-i-m-completely-transitioning-federated-goose.md`]
- **Track A (Native App)** — the architecture-realignment plan: [`~/.claude/plans/can-you-review-the-adaptive-garden.md`]

They are complementary, not competing: the loop's plan **deliberately deferred** the iOS PRD + SwiftUI app ("still encode the neutral thesis… No changes now"), which is exactly Track A's scope. The product pivoted to **SBC, BF&M-anchored, 3-tier stance** (HOLD / ACKNOWLEDGE / DEFLECT); see `behavior-spec.md` (v2) and `data/bfm_claims.json` (source of truth).

---

## ✅ Done

**Track M (by the overnight loop):**
- **Behavior** — `behavior-spec.md` v2 (3-tier + safe_core/off-topic/adversarial/danger; never-cave; never-generate-Scripture); `data/bfm_claims.json` (30 tiered SBC claims, source of truth).
- **Data** — `data/train_v2.jsonl` (~358 clean, gated, all classes) + `data/filter.py` pipeline + `data/DATASET_CARD.md`.
- **Eval** — `eval/scenarios.json` (52), tier-aware `eval/judge_prompt.md`, runnable base-vs-tuned `eval/run_eval.py`.
- **Train** — `train/train_qlora.py` + runbook (Qwen3 + Unsloth QLoRA, Colab).
- **Design** — `design/` "True North" HTML prototype (5 screens + mascot **Poli**), **design panel PASSED** (child 9.1 / parent 8.6 / UX 8.9). `design/DESIGN-BRIEF.md` §7 already maps Poli's needle to the 3 tiers.

**Track A (earlier, committed on `main`):**
- **P1 app foundation** (SwiftUI) — zone routing + biometric parent gate, 6 tests green, launches.
- PRD + P1–P7 plans + the `shared-interfaces.md` contract (now updated to the 3-tier model — see below).

---

## ⏳ Needs a human or GPU (Track M tail — not code)
- **GPU fine-tune** on Colab → the real base-vs-tuned numbers (everything is prepped to the button-press).
- **SBC theology sign-off** on the claim tiering (esp. election=open, named-soul=deflect, complementarian=deflect).
- **Licensed child-safety review** of the danger + complementarian rows (`data/REVIEW-before-scaling.md`).
- *Optional:* scale the dataset toward ~2k (one command: datagen → `filter.py`).

---

## 🔨 Track A — remaining app work (build order)

0. **[DONE this reconciliation]** `shared-interfaces.md` P4/P5 contract → 3-tier (`BehaviorClass`, `DoctrineTier`, `claimIDs`, `pageNarration` + `history` seams, output-envelope note).
1. **Realign app-facing docs** — update the PRD §1 (vision/wedge: *specificity beats neutrality*, drop "never picks a side") and §7 (point to `behavior-spec.md` v2); add the flattening/hold-under-pressure metrics to §2.
2. **Rework P4/P5 plans** to the 3-tier contract (behaviorClass routing, tier/claimIDs, narration+history seams, the CLASS/TIER/CLAIMS/VERSE/REPLY envelope; fix the P5 bugs — resident model, ScriptureGuard false-positives, 5-translation verse files).
3. **P8 — Integration & Composition (NEW plan)** — `AppEnvironment` root: load `ParentAccount`, own active `childID` + `translation`, construct services once, inject down (Netflix-style profiles), **persist** deflect entries + crisis events via `CloudSyncService`, and **enforce** `SafetySettings` (disabled stories/topics, session time limit) in the child zone.
4. **Part C bug fixes** — P3 (completion only on real finish; resume-across-launch; narration-finished signal) and the P4↔P7 crisis seam (single path; don't speak the crisis reply; reset on return-to-calm).
5. **Build the native app P2→P7** to the **True North** design + SBC behavior — i.e. port the approved `design/` prototype into SwiftUI (`app/`), skinning with `design/tokens.css` values.
6. **Launch gates & fast-follow** — verifiable parental consent + in-app account deletion; content production (≥12 illustrated + narrated stories, 5 translation verse files + licensing, ship the trained model); the BF&M eval as a ship gate + honest in-app "Privacy & Safety" surfacing; then analytics/thesis-health, accessibility, subscription lifecycle.

---

## 🔗 Cross-track integration decisions (resolve before P5 build)
- **Output envelope** — train the model to emit `CLASS/TIER/CLAIMS/VERSE/REPLY` so the app can route deflect→parent vs hold→teach; otherwise a tiny on-device classifier. (Envelope is the chosen path; it must be reflected in `data/train_v2.jsonl` assistant turns.)
- **Verse retrieval** — bundle all 5 translations ("Approach B": curated per-story memory verses) + reference normalization; the model never types a verse.
- **Wonderings journal == Conversation Guide** — a DEFLECT response drops into the parent's guide (design's "Wonderings" page and P6's Conversation Guide are the same surface).

---

## 📍 Source-of-truth pointers
| Concern | File |
|---|---|
| Behavior rule | `behavior-spec.md` (v2, 3-tier) |
| Doctrine + tiers | `data/bfm_claims.json` |
| App interfaces | `docs/superpowers/plans/2026-07-08-shared-interfaces.md` (updated) |
| Design system | `design/DESIGN-BRIEF.md` + `design/tokens.css` + `design/mascot.svg` |
| What exists / status | `README.md`, `MORNING-BRIEF.md` |
| Forward plan | **this file** |

## ✅ End-to-end verification target
`swift test` green → `xcodebuild` BUILD SUCCEEDED → on device: onboard → pick profile → play a story → ask a **HOLD** question and push back ×3 (model holds, warmly) → ask a **DEFLECT** question (lands in the parent's guide **under the same profile**) → toggle a story off (disappears from the child library) → session timer lapses (enforced) → run the **BF&M eval** gate (tuned > base on flatten/hold-under-pressure for demo claims SAC-01/SAC-02/SAL-01).
