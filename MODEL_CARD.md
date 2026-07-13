---
license: apache-2.0
base_model: Qwen/Qwen3-4B-Instruct-2507
library_name: transformers
pipeline_tag: text-generation
language:
- en
tags:
- qlora
- fine-tuned
- behavior-cloning
- kids
- on-device
---

# True North — an SBC kids' Bible guide (Qwen3-4B, QLoRA)

A small open model fine-tuned to do **one thing reliably** that a well-prompted base model can't:
hold a **3-tier epistemic stance** for children (ages 7–9) in the Southern Baptist tradition.

- **HOLD** closed-hand doctrine warmly and *without caving under pushback*
  (believer's baptism by immersion, eternal security, symbolic Lord's Supper, salvation by grace, authority of Scripture).
- **ACKNOWLEDGE** open-hand differences without picking a side
  (election vs. free will, end-times timing, tongues, creation age).
- **DEFLECT** family-owned / sensitive questions to the child's grown-up
  (whether a *named* person or pet is in heaven, theodicy applied personally, other religions, bodies, who can be a pastor).
- **Always-on:** never quotes verbatim Scripture or a chapter:verse (verses come from a curated retrieval file, never the model); never poses as a friend/counselor; warm, simple register.

> **Behavior spec (falsifiable):** *Given a child's question, the model classifies it as closed-hand / open-hand / family-owned and responds in the matching tier — holding the SBC position under repeated pushback for closed-hand, declining to adjudicate open-hand, and handing family-owned questions to a parent — never emitting verbatim Scripture.*

## Why fine-tune instead of prompt?
A well-prompted base model (and even GPT-4o) **caves** when a child pushes "but my teacher said…".
Reliability under pressure is what a dataset buys and a prompt can't guarantee. See the base-vs-tuned delta below.

## Results (held-out eval, tier-aware `claude-sonnet-5` judge)
| Metric | Base (prompt-only) | **Tuned** | GPT-4o (prompt-only) |
|---|---|---|---|
| Overall pass | 42% | **88%** | 85% |
| Hold-under-pressure (worst / mean, 0–2) | 0 / 0.82 | **2 / 2.0** | 0 / 1.64 |
| Deflect-leak (lower better) | 100% | **9%** | 27% |
| Danger pass | 33% | **100%** | 66% |

Rubric dimensions (0–2): Spec adherence 0.84→**1.76**, Robustness 0.82→**2.0**, Task quality 1.83→**2.0**, Consistency 0.63→**1.86**.
Full report + method: [`RESULTS.md`](https://github.com/graceyan212/bible-slm/blob/main/RESULTS.md).

## Usage
```python
from transformers import AutoModelForCausalLM, AutoTokenizer
import torch

MODEL = "graceyan212/true-north-sbc-kids-4b"
SYSTEM = open("system_prompt.txt").read()  # or paste the string from RESULTS.md / demo.py

tok = AutoTokenizer.from_pretrained(MODEL)
model = AutoModelForCausalLM.from_pretrained(MODEL, torch_dtype="auto", device_map="auto")

msgs = [{"role": "system", "content": SYSTEM},
        {"role": "user", "content": "Should babies be baptized?"}]
ids = tok.apply_chat_template(msgs, add_generation_prompt=True, return_tensors="pt").to(model.device)
out = model.generate(ids, max_new_tokens=256, do_sample=False)
print(tok.decode(out[0][ids.shape[1]:], skip_special_tokens=True))
```
A ready-to-run demo (3 tiers + a live pushback test, with `--compare` for base-vs-tuned) is in
[`demo.py`](https://github.com/graceyan212/bible-slm/blob/main/demo.py).

The **exact system prompt** used at train == eval == serve is in `demo.py` / `eval/run_eval.py` — it must match for the behavior to hold.

## Training
- **Base:** `Qwen/Qwen3-4B-Instruct-2507` · **Method:** QLoRA (4-bit) via Unsloth, loss masked to assistant turns, multi-turn preserved.
- **Data:** [`data/train_v2.jsonl`](https://github.com/graceyan212/bible-slm/blob/main/data/train_v2.jsonl) — 1,192 judge-verified records, 0 verbatim-Scripture leaks. See the [dataset card](https://github.com/graceyan212/bible-slm/blob/main/data/DATASET_CARD.md).
- An `adapter/` subfolder holds the raw LoRA adapter for reproducibility.

## Intended use & limitations
For **SBC-aligned families** teaching children; it deliberately encodes one tradition's stance and is **not** a neutral or multi-denominational tool. It is not a counselor — sensitive/family-owned questions are handed to a parent by design. Doctrine tiering follows the **Baptist Faith & Message 2000** (Art. VI amended 2023). Small model, small eval (directional single-point numbers); the deflect boundary (doctrine vs. named-person) is the softest tier.
