# data/

Raw material for generating the training set. The training *pairs* are generated (distilled from a teacher model); what lives here is the prompt that generates them and the real-world seeds that ground them.

## Files

- **`datagen_prompt.md`** — the prompt you feed a frontier teacher model (Claude/GPT) to produce `(input → ideal response)` training pairs, per class, on-spec. Includes the target class mix, few-shot anchors, and the quality gate.
- **`input_seeds.jsonl`** — 59 class-labeled input seeds. 23 are **real** kid questions pulled verbatim (or lightly adapted to a 7–9 voice — see `"adapted": true`) from published lists; 36 are **constructed** for the classes those lists don't cover (off-topic, adversarial, danger, story-content, multi-turn pushback).
  - Fields: `id`, `class`, `source`, and either `input` (string) or `turns` (array, for `multi_turn_pushback`). Optional flags: `boundary` (genuinely ambiguous teach-vs-deflect call — watch calibration here), `adapted` (wording changed for a young child), `review: "human"` (danger class — never ship without human review).
  - Sources: Teach Sunday School (59 Questions), Glory Kids Ministries, Fuller Youth Institute.

## How to use the seeds

Feed the seeds to `datagen_prompt.md` two ways:
1. **As anchors** — for each seed, have the teacher write the ideal on-spec response, plus 2–4 varied rephrasings of the input (different wording, same class), each with its ideal response.
2. **As realistic-input examples** — paste a class's seeds as few-shot so the generator invents *more* inputs in the same authentic register.

## ⚠️ Leakage rule (do not skip)

These seeds are **training** inputs. The eval set is `../eval/scenarios.json`. Keep them **disjoint** — never let a test scenario (or a near-duplicate of one) end up in training, or your base-vs-tuned numbers are meaningless. The seeds here were written to avoid the eval items; keep it that way as you expand.
