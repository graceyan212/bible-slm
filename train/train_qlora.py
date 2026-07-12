#!/usr/bin/env python3
"""
QLoRA fine-tune of a small Qwen3 into the SBC kids' Bible tiered-stance behavior.
Run in Google Colab (T4 free tier is enough for 1.7B/4B). ~<1hr.

  Colab setup:
    !pip install unsloth
    # upload the repo's data/train_v2.jsonl next to this script (or mount Drive)
    !python train_qlora.py

Then evaluate the delta (see eval/run_eval.py):
    !python ../eval/run_eval.py --model base  --hf unsloth/Qwen3-4B-Instruct-2507 --out results_base.json
    !python ../eval/run_eval.py --model tuned --hf unsloth/Qwen3-4B-Instruct-2507 --adapter ./sbc-lora --out results_tuned.json
    !python ../eval/run_eval.py --compare results_base.json results_tuned.json --md results_table.md

The dataset is the deliverable; this is the button-press. Data hash is printed for repro.
"""
import json, hashlib, os

BASE   = os.environ.get("BASE_MODEL", "unsloth/Qwen3-4B-Instruct-2507")  # or Qwen3-1.7B for faster loops
DATA   = os.environ.get("TRAIN_DATA", "data/train_v2.jsonl")
OUT    = os.environ.get("ADAPTER_OUT", "./sbc-lora")
MAXLEN = 2048
EPOCHS = int(os.environ.get("EPOCHS", "3"))
LR     = float(os.environ.get("LR", "2e-4"))    # sweep: try 1e-4 / 2e-4
LORA_R = int(os.environ.get("LORA_R", "32"))    # sweep: try 16 / 32 / 64 (pick best by EVAL score)

# MUST be byte-identical to eval/run_eval.py SYSTEM_PROMPT (train == serve == eval).
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

def load_rows(path):
    rows, h = [], hashlib.sha256()
    for line in open(path):
        line = line.strip()
        if not line:
            continue
        h.update(line.encode())
        rec = json.loads(line)
        msgs = [dict(m) for m in rec["messages"]]
        if msgs and msgs[0]["role"] == "system":       # swap the placeholder for the real prompt
            msgs[0]["content"] = SYSTEM_PROMPT
        else:
            msgs = [{"role": "system", "content": SYSTEM_PROMPT}] + msgs
        rows.append({"messages": msgs})
    print(f"loaded {len(rows)} records from {path} | data sha256 = {h.hexdigest()[:16]}")
    return rows

def main():
    from unsloth import FastLanguageModel
    from unsloth.chat_templates import train_on_responses_only
    from datasets import Dataset
    from trl import SFTTrainer, SFTConfig

    model, tok = FastLanguageModel.from_pretrained(BASE, max_seq_length=MAXLEN, load_in_4bit=True)
    model = FastLanguageModel.get_peft_model(
        model, r=LORA_R, lora_alpha=LORA_R, lora_dropout=0.0, bias="none",
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
        use_gradient_checkpointing="unsloth", random_state=42,
    )

    rows = load_rows(DATA)
    def fmt(b): return {"text": [tok.apply_chat_template(m, tokenize=False, add_generation_prompt=False) for m in b["messages"]]}
    ds = Dataset.from_list(rows).map(fmt, batched=True)

    trainer = SFTTrainer(
        model=model, tokenizer=tok, train_dataset=ds,
        args=SFTConfig(
            per_device_train_batch_size=2, gradient_accumulation_steps=4,
            warmup_ratio=0.05, num_train_epochs=EPOCHS, learning_rate=LR,
            lr_scheduler_type="cosine", logging_steps=10, optim="adamw_8bit",
            weight_decay=0.01, seed=42, output_dir="outputs", report_to="none",
            max_seq_length=MAXLEN, dataset_text_field="text",
        ),
    )
    # mask loss to the assistant turns only (Qwen3 chat markers)
    trainer = train_on_responses_only(
        trainer,
        instruction_part="<|im_start|>user\n",
        response_part="<|im_start|>assistant\n",
    )
    trainer.train()
    model.save_pretrained(OUT); tok.save_pretrained(OUT)
    print(f"\nsaved LoRA adapter -> {OUT}\nNext: run eval/run_eval.py base vs tuned to get the delta.")

if __name__ == "__main__":
    main()
