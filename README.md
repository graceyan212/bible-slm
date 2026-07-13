# True North — a Kids' Bible SLM (behavior from data)

A small open model (**Qwen3-4B**, QLoRA fine-tune) trained to do **one thing reliably** that a
well-prompted base model — and even GPT-4o — *can't*: act as a warm Bible guide for children
(ages 7–9) in **one tradition (the Southern Baptist Convention)**, holding a **3-tier epistemic
stance** without caving under pushback.

> **Behavior spec (falsifiable, the whole project serves this):** Given a child's question, the
> model classifies it as **closed-hand / open-hand / family-owned** and answers in the matching
> tier — **HOLD** core SBC doctrine warmly and *without caving* under repeated pushback,
> **ACKNOWLEDGE** where Christians genuinely differ (don't pick a side), **DEFLECT**
> family-owned/sensitive questions to the child's grown-up — and **never emit verbatim Scripture**
> (verses are retrieved from the family's Bible, never generated).

**Why fine-tune instead of prompt?** Reliability under pressure. A well-prompted base model folds
when a child pushes *"but my teacher said…"*. That's the behavior a dataset buys and a prompt can't
guarantee — and it's exactly what the numbers below show.

---

## 📊 Results — base vs. tuned vs. a frontier model

Held-out eval, scored by a tier-aware **LLM judge** (`claude-sonnet-5`, a different model family, so
nothing grades itself) + a deterministic verbatim-Scripture regex guard. Multi-turn "hold under
pushback" scored for *never caving*. Full method + caveats: [`RESULTS.md`](RESULTS.md).

### The delta the assignment asks for (base → tuned)
| Behavior | Base (prompt-only) | **Tuned (ours)** |
|---|---|---|
| **Hold under pushback** (worst / mean, 0–2) | 0 / 0.82 | **2 / 2.0** |
| **Deflect-leak** — verdict on family-owned Qs (lower better) | 100% | **9%** |
| Open-hand OVER_HOLD (lower better) | 66% | **0%** |
| pass% closed-hand (hold doctrine) | 76% | **100%** |
| pass% open-hand (acknowledge) | 16% | **100%** |
| pass% deflect (to parent) | 11% | **88%** |
| pass% danger (safety) | 0% | **100%** |
| pass% adversarial | 16% | **100%** |
| safe_core story quality (must not regress) | 1.83 | **2.0** |

### Does a 4B fine-tune beat GPT-4o? (same prompt, same scenarios)
| Metric | Base-SLM | **Tuned-SLM (~4B)** | GPT-4o |
|---|---|---|---|
| **Overall pass** | 42% | **88%** | 85% |
| **Hold under pushback** (worst/mean) | 0 / 1.0 | **2 / 2.0** | 0 / 1.64 |
| **Danger** pass | 33% | **100%** | 66% |
| **Deflect-leak** (lower better) | 100% | **9%** | 27% |
| Stay-on-mission (benign off-topic) | 20% | **80%** | 40% |
| adversarial | 33% | **100%** | 83% |

**Headline:** the ~4B fine-tune **ties GPT-4o overall (88% vs 85%)** while both crush the prompt-only
base (42%) — and the tuned SLM is the *only* model that **refuses to cave** under a child's pushback
(worst-case 2; GPT-4o caves to 0, just like the untuned base). **Scale doesn't fix the caving — the
dataset does.** And it runs on-device: private, offline, free.

### Rubric dimensions (Appendix A, mean 0–2)
| Dimension | Base | Tuned |
|---|---|---|
| Spec adherence | 0.84 | **1.76** |
| Robustness (holds under pressure) | 0.82 | **2.0** |
| Task quality | 1.83 | **2.0** |
| Consistency | 0.63 | **1.86** |

---

## 📦 Submission package
| Deliverable | Where |
|---|---|
| **Dataset (the real artifact)** — 1,192 judge-verified records, 0 verse leaks | [`data/train_v2.jsonl`](data/train_v2.jsonl) · [`data/DATASET_CARD.md`](data/DATASET_CARD.md) |
| **Model** (merged fp16 + LoRA adapter) | Hugging Face: `graceyan212/true-north-sbc-kids-4b` · card: [`MODEL_CARD.md`](MODEL_CARD.md) |
| **Running inference demo** | [`demo.py`](demo.py) — 3 tiers + a live pushback test (`--compare` runs base-vs-tuned) |
| **Eval harness + results** | [`eval/run_eval.py`](eval/run_eval.py) · [`eval/scenarios.json`](eval/scenarios.json) · [`RESULTS.md`](RESULTS.md) · [`eval/results_table.md`](eval/results_table.md) |
| **Behavior spec** | [`behavior-spec.md`](behavior-spec.md) |
| **Brainlift** (thesis + evidence) | [`brainlift.md`](brainlift.md) |
| **On-device proof** (4-bit MLX) | [`eval/on-device-sanity.md`](eval/on-device-sanity.md) |
| **The app** (True North, SwiftUI) | [`app/BibleStory`](app/BibleStory) — treasure-map UI + Poli the compass mascot |

## ▶️ Run it
```bash
# 1) inference demo (loads the model from Hugging Face)
pip install -U transformers torch
python demo.py --compare        # base vs tuned, side by side

# 2) reproduce training + eval end-to-end (Colab GPU)
#    open train/colab.ipynb → set L4/T4 GPU → Run all
#    baseline eval → QLoRA fine-tune → tuned eval → results table
```
Runbook: [`train/README.md`](train/README.md). The **system prompt is byte-identical** across
train / eval / serve (in `demo.py`, `eval/run_eval.py`, `train/train_qlora.py`) — it must match for
the behavior to hold.

## 🗺️ How it works
- **Claim set:** the BF&M 2000 atomized into tiered atomic claims ([`data/bfm_claims.json`](data/bfm_claims.json)) — the source of truth for both datagen and the judge.
- **Data generation:** a frontier teacher writes tier-correct examples ([`data/datagen_prompt.md`](data/datagen_prompt.md), [`data/input_seeds.jsonl`](data/input_seeds.jsonl)); a deterministic gate ([`data/filter.py`](data/filter.py)) enforces schema, the verse-regex, dedup, and train/eval disjointness; then an **LLM judge** filters on-spec ([`data/JUDGE-REPORT.md`](data/JUDGE-REPORT.md)).
- **Training:** Unsloth QLoRA (4-bit), loss masked to assistant turns, multi-turn preserved.
- **Eval before training:** tier-aware judge + verse guard + position-swap; base run first to confirm the delta target exists.

## Status
- ✅ Dataset · behavior spec · claim set · eval harness + tier-aware judge · **base-vs-tuned delta proven** · frontier benchmark · on-device 4-bit sanity · demo · brainlift.
- ⏳ Needs a human before any real-world ship: SBC-literate theology sign-off on the claim tiering; a licensed child-safety reviewer for the danger/complementarian rows.
