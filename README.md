# Treasure Trail — SBC Kids' Bible SLM + App

A small, fine-tuned language model that acts as a warm Bible **guide for children (ages 7–9)**,
faithfully representing **one tradition — the Southern Baptist Convention** — plus an
adventure-coded app UI ("Treasure Trail" — a warm treasure-map / explorer's-journal world) with a
brass compass mascot, **Poli**, as the AI.

**The thesis:** general AI fails at faith not by lack of smarts but by *flattening* every
tradition into a generic "Christians believe…". So we anchor to one tradition and train a
**3-tier stance**: **HOLD** the closed-hand core doctrine confidently (never caving), **ACKNOWLEDGE**
where Christians genuinely differ, and **DEFLECT** family-owned/sensitive questions to the parent —
and the model **never generates verbatim Scripture** (verses are retrieved from the family's Bible).
The dataset (not the model) is the deliverable; the same flatten-rate is the eval metric.

## Start here
- **Read:** [`MORNING-BRIEF.md`](MORNING-BRIEF.md) — what's built, what needs you, status.
- **See the app:** open [`design/index.html`](design/index.html) in a browser → `home.html` (constellation trail), `lesson.html` (story + Ask-Poli), `compass.html` (SLM chat/voice + guided-topic picker). Design system + mascot in `design/tokens.css` + `design/mascot.svg`; rationale in `design/DESIGN-BRIEF.md`; review record in `design/PANEL.md` (**panel PASSED**).
- **Run the model** (your Colab GPU): [**▶️ open `train/colab.ipynb` in Colab**](https://colab.research.google.com/github/graceyan212/bible-slm/blob/main/train/colab.ipynb) (set T4 GPU → Run all) — baseline eval → QLoRA fine-tune → tuned eval → results table. Runbook: [`train/README.md`](train/README.md).

## Repo map
| Path | What |
|---|---|
| `brainlift.md` | Research → strategy (SPOVs, why AI fails, the SBC pivot) |
| `behavior-spec.md` | The falsifiable 3-tier behavior rule (datagen rubric + eval criterion) |
| `data/bfm_claims.json` | 30 atomic BF&M claims, tiered — **source of truth** for datagen + eval |
| `data/datagen_prompt.md` · `input_seeds.jsonl` · `filter.py` | The generation pipeline |
| `data/train_v2.jsonl` | The dataset (v1 = 358 clean, gated records) |
| `data/DATASET_CARD.md` | Dataset card |
| `eval/scenarios.json` · `judge_prompt.md` · `run_eval.py` | Held-out eval (52 scenarios) + tier-aware judge + base-vs-tuned harness |
| `train/train_qlora.py` · `README.md` | Unsloth QLoRA fine-tune + Colab runbook |
| `design/` | The app UI (Treasure Trail) + Poli mascot + design panel record |
| `data/REVIEW-before-scaling.md` | Human-review packet (theology + safety rows) |

## Status
- ✅ Brainlift · behavior spec · claim set · eval (52 scenarios) + tier-aware judge + runnable harness · datagen pipeline · **dataset v1 (358 clean)** + card · UI (5 screens + Poli, **design panel passed** 8.6–9.1) with the SLM interaction wired (mock stub, clear real-endpoint hook) · QLoRA train script + Colab runbook.
- ⏳ Needs **your GPU** (Colab): the actual fine-tune + the real base-vs-tuned numbers (everything is prepped to the button-press).
- ⏳ Needs **humans before ship:** SBC-literate theology sign-off on the claim tiering; a licensed child-safety reviewer for the danger + complementarian rows.
- ↗️ Optional: scale the dataset toward ~2k (one command — re-run datagen → filter); port the HTML screens to the SwiftUI `app/`.
- ✅ Your inspiration **vibes PDF arrived and the app is re-skinned to it** — treasure-map / parchment / brass compass / storybook type, from your swatch palette. Tweaks are one small edit (it's all tokenized). See the skin note atop `design/DESIGN-BRIEF.md`.
