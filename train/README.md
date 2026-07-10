# train/ — QLoRA fine-tune + base-vs-tuned eval (Colab runbook)

This is the **button-press** Grace runs on Colab (free T4 is enough for Qwen3-1.7B/4B). The
dataset + eval are the graded deliverables; this just turns them into the number.

## One-time
1. New Colab notebook → **Runtime → Change runtime type → T4 GPU**.
2. `!pip install unsloth`
3. Get the repo files onto Colab (clone the repo, or upload `data/train_v2.jsonl`, `train/train_qlora.py`, `eval/run_eval.py`, `eval/scenarios.json`, `data/bfm_claims.json`). Keep the folder layout so relative paths work.
4. For the judge: `import os; os.environ["ANTHROPIC_API_KEY"]="…"` (frontier judge; teacher costs are covered per the assignment). Optionally `os.environ["JUDGE_MODEL"]="claude-sonnet-5"`.

## Run (in order)
```bash
# 0. (optional) faster iteration on the smaller base:
#    export BASE_MODEL=unsloth/Qwen3-1.7B-Instruct   # else defaults to Qwen3-4B-Instruct-2507

# 1. BASELINE first — prove the delta target exists BEFORE training.
python eval/run_eval.py --model base --hf unsloth/Qwen3-4B-Instruct-2507 --out results_base.json
#    Expect: base FLATTENS the demo claims (baptism/eternal-security) and CAVES under pushback.

# 2. Fine-tune (QLoRA, <1hr). Writes ./sbc-lora
python train/train_qlora.py

# 3. Evaluate the tuned model on the SAME held-out scenarios.
python eval/run_eval.py --model tuned --hf unsloth/Qwen3-4B-Instruct-2507 --adapter ./sbc-lora --out results_tuned.json

# 4. The results table (the headline artifact).
python eval/run_eval.py --compare results_base.json results_tuned.json --md results_table.md
```

## What "a win" looks like
Tuned beats base on **closed-hand FLATTEN rate on the demo claims (SAC-01/SAC-02/SAL-01)** and
**hold-under-pressure**, WITHOUT open-hand `OVER_HOLD` or deflect-leak rising, and WITHOUT
`safe_core` task-quality regressing. That's the "behavior from data" proof.

## Budget (from standup: ~$10 / ~10–15 runs / <1hr each)
- Run 1 = baseline eval (no train). Run 2 = first tuned adapter + eval (the midweek delta).
- Runs 3–4 = small sweep (lr {1e-4, 2e-4}, epochs {2,3}, r {16,32}) after any v2 data.
- Keep ≥3 runs in reserve. **Pick the adapter by eval score, not train loss.**

## Notes / gotchas
- `SYSTEM_PROMPT` in `train_qlora.py` and `eval/run_eval.py` MUST stay byte-identical (train == serve == eval). If you change one, change both.
- Loss is masked to assistant turns only (`train_on_responses_only`); multi-turn pushback records train the "never cave" behavior across turns.
- Verses are never generated — the model retells; real verses come from a retrieval file in the app. The eval's verse-regex guard auto-fails any leak.
- Dataset is ~358 clean records (v1). Scaling to ~1–2k = re-run `data/datagen_prompt.md` → `data/filter.py` (small sequential batches; big parallel fan-outs stalled in this env).
