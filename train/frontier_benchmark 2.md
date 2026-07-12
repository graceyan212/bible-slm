# Frontier vs. your SLM — benchmark (API-only, no GPU)

Runs a **frontier model** (e.g. GPT-4o) through the **same 52 held-out scenarios + the same tier-aware
judge** your SLM was scored on. You then compare its pass rates to your tuned SLM's numbers
(in `../eval/results_table.md`) for an honest "vs. frontier, by how much" answer.

**No GPU, no training** — it's all API calls. A plain Colab CPU runtime (or your laptop) is fine.

## Run it (paste into a Colab cell, or run locally)
```python
# 1. get the code + the OpenAI SDK
!git clone https://github.com/graceyan212/bible-slm.git
%cd bible-slm
!pip install -q openai anthropic

# 2. gateway config (your TrueFoundry key)
import os, getpass
os.environ["JUDGE_BASE_URL"] = "https://gateway.truefoundry.ai"     # your gateway
os.environ["JUDGE_API_KEY"]  = getpass.getpass("TrueFoundry key: ") # your user-... key
os.environ["JUDGE_MODEL"]    = "claude-sonnet-5"                    # the JUDGE (same one that scored your SLM)
os.environ["GEN_MODEL"]      = "openai-group/gpt-4o"                # the FRONTIER CONTESTANT (keep ≠ the judge)

# 3. run the frontier model through the same eval, then print its metrics
!python eval/run_eval.py --model frontier --backend gateway --out results_frontier.json
!python eval/run_eval.py --metrics results_frontier.json
```

## Notes
- **Keep the contestant ≠ the judge.** Judge is `claude-sonnet-5`, so test a *non-Claude* frontier
  (e.g. `openai-group/gpt-4o`, `openai-group/gpt-5`) to avoid a model grading itself. You can also test
  a Claude (`claude-group/claude-opus-4-8`) — just note it's same-family as the judge (mild leniency).
- Want two contestants? Change `GEN_MODEL` and re-run to a new `--out results_frontier_opus.json`.
- The frontier gets the **same steelman 3-tier system prompt** as base/tuned — a fair, best-prompt-only shot.
- **Send me `results_frontier.json`** (or paste the `--metrics` output) and I'll build the three-way
  table: **frontier vs. base-SLM vs. tuned-SLM** (base/tuned columns come from `eval/results_table.md`).
- If a model errors on a parameter (e.g. `max_tokens`), tell me the message and I'll adjust one line.
