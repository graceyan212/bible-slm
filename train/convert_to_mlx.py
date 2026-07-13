#!/usr/bin/env python3
"""Merge the SBC QLoRA adapter into the fp16 Qwen3-4B base and convert to MLX 4-bit,
producing an on-device model directory the app's MLXModelEngine loads.

    python train/convert_to_mlx.py
Env overrides: BASE_MODEL, ADAPTER, MERGED, MLX_OUT.
"""
import os, sys, subprocess
from pathlib import Path
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
from peft import PeftModel

BASE    = os.environ.get("BASE_MODEL", "unsloth/Qwen3-4B-Instruct-2507")  # fp16 base (matches train/eval)
ADAPTER = os.environ.get("ADAPTER", str(Path.home() / "Downloads" / "sbc-lora"))
MERGED  = os.environ.get("MERGED", "sbc-merged")
MLX_OUT = os.environ.get("MLX_OUT", "sbc-mlx-4bit")

print(f"[1/3] load base {BASE} + merge adapter {ADAPTER}", flush=True)
# The adapter ships its own tokenizer + chat template — use it so serve == train.
tok = AutoTokenizer.from_pretrained(ADAPTER)
base = AutoModelForCausalLM.from_pretrained(BASE, torch_dtype=torch.float16, device_map="cpu")
model = PeftModel.from_pretrained(base, ADAPTER)
model = model.merge_and_unload()          # fold LoRA into the base weights
model.save_pretrained(MERGED, safe_serialization=True)
tok.save_pretrained(MERGED)
print(f"[2/3] merged HF model → {MERGED}", flush=True)

print(f"[3/3] MLX 4-bit convert → {MLX_OUT}", flush=True)
# mlx_lm CLI moved between `mlx_lm convert` and `mlx_lm.convert` across versions — try both.
cmd = [sys.executable, "-m", "mlx_lm", "convert", "--hf-path", MERGED, "-q", "--q-bits", "4", "--mlx-path", MLX_OUT]
r = subprocess.run(cmd)
if r.returncode != 0:
    subprocess.run([sys.executable, "-m", "mlx_lm.convert", "--hf-path", MERGED,
                    "-q", "--q-bits", "4", "--mlx-path", MLX_OUT], check=True)
print("DONE:", MLX_OUT, flush=True)
