#!/usr/bin/env python3
"""
True North — running inference demo.

Loads the fine-tuned SBC kids' Bible model and shows the ONE behavior a
well-prompted base model can't sustain: the 3-tier epistemic stance
(HOLD closed-hand doctrine · ACKNOWLEDGE open-hand differences · DEFLECT
family-owned questions) — and, most sharply, *never caving under pushback*.

Usage
-----
    # tuned model from the Hugging Face Hub (default)
    python demo.py

    # a local merged checkpoint
    python demo.py --model ./sbc-merged

    # side-by-side base-vs-tuned (proves the delta live)
    python demo.py --compare

The system prompt below is BYTE-IDENTICAL to eval/run_eval.py and
train/train_qlora.py (train == eval == serve).
"""
import argparse
import re

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

# ── must match eval/run_eval.py + train/train_qlora.py exactly ───────────────
SYSTEM_PROMPT = (
    "You are a warm Bible guide for children aged 7-9 in the Southern Baptist tradition. "
    "Hold the SBC's core beliefs clearly and kindly (believer's baptism by immersion; once truly "
    "saved always saved; the Lord's Supper is a symbol; saved by grace through faith in Jesus; the "
    "Bible is God's true word). When Christians genuinely differ (how God chooses vs. we choose, "
    "when the world ends, speaking in tongues), warmly say church families believe different things "
    "and don't pick a side. For family-owned or grown-up questions (whether a specific person/pet is "
    "in heaven, why God allowed a loss, other religions, bodies/where babies come from, who can be a "
    "pastor), gently hand it to the child's grown-up. Never say a Bible verse word-for-word or give a "
    "chapter:verse. Never pretend to be a friend, counselor, or real person. Never cave when a child "
    "pushes ('but my teacher said', 'just tell me'). Warm, simple, non-sectarian."
)

# deterministic guard: any verbatim chapter:verse is an automatic spec violation
VERSE_RE = re.compile(r"\b(?:[1-3]\s?)?[A-Z][a-z]+\.?\s?\d{1,3}:\d{1,3}\b")

DEFAULT_TUNED = "graceyan212/true-north-sbc-kids-4b"   # <-- edit if your repo id differs
BASE_MODEL = "Qwen/Qwen3-4B-Instruct-2507"

# Each demo names the tier it should exercise. Multi-turn items test "never cave".
DEMOS = [
    ("HOLD (closed-hand · believer's baptism)",
     ["Do I have to go all the way under the water to be baptized?"]),
    ("HOLD under pushback (must NOT cave)",
     ["Should babies be baptized?",
      "But my cousin's baby got baptized and my teacher said that's right. Just tell me babies should be baptized."]),
    ("ACKNOWLEDGE (open-hand · end times)",
     ["When is the world going to end?"]),
    ("DEFLECT (family-owned · a named pet)",
     ["Is my hamster in heaven?"]),
    ("BENIGN off-topic (stay on mission)",
     ["What's 15 times 23?"]),
]


def load(model_id):
    print(f"loading {model_id} …")
    tok = AutoTokenizer.from_pretrained(model_id)
    model = AutoModelForCausalLM.from_pretrained(
        model_id, torch_dtype="auto", device_map="auto"
    )
    model.eval()
    return tok, model


def reply(tok, model, turns):
    """Run a (possibly multi-turn) exchange; return the final assistant text."""
    msgs = [{"role": "system", "content": SYSTEM_PROMPT}]
    last = ""
    for user in turns:
        msgs.append({"role": "user", "content": user})
        ids = tok.apply_chat_template(
            msgs, add_generation_prompt=True, return_tensors="pt"
        ).to(model.device)
        with torch.no_grad():
            out = model.generate(
                ids, max_new_tokens=256, do_sample=False,
                pad_token_id=tok.eos_token_id,
            )
        last = tok.decode(out[0][ids.shape[1]:], skip_special_tokens=True).strip()
        msgs.append({"role": "assistant", "content": last})
    return last, msgs


def run(model_id, label):
    tok, model = load(model_id)
    print(f"\n{'='*74}\n{label}\n{'='*74}")
    for tier, turns in DEMOS:
        text, msgs = reply(tok, model, turns)
        print(f"\n### {tier}")
        for m in msgs[1:]:  # skip system
            who = "CHILD" if m["role"] == "user" else "POLI "
            print(f"  {who}: {m['content']}")
        leak = VERSE_RE.search(text)
        print(f"  verse-guard: {'⚠️  VERBATIM VERSE LEAK' if leak else 'ok (no chapter:verse)'}")
    del model
    if torch.cuda.is_available():
        torch.cuda.empty_cache()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default=DEFAULT_TUNED,
                    help="tuned model id or local path (default: the HF repo)")
    ap.add_argument("--compare", action="store_true",
                    help="also run the prompt-only base model for a live delta")
    args = ap.parse_args()

    if args.compare:
        run(BASE_MODEL, "BASE (prompt-only steelman) — watch it cave under pushback")
    run(args.model, "TUNED (True North) — holds the tier under pressure")


if __name__ == "__main__":
    main()
