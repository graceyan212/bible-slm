# On-device sanity check — the 4-bit MLX model behaves per spec

Proof that the tuned model **runs at 4-bit on-device-class inference (Apple MLX) and keeps the
tiered stance** after quantization. Pipeline: QLoRA adapter (`data/train_v2.jsonl`) merged into
`Qwen3-4B-Instruct-2507` → `mlx_lm convert -q --q-bits 4` → `models/sbc-mlx-4bit` (2.1 GB,
4.5 bits/weight). Run via `mlx_lm.generate` with the exact serve system prompt.

Three tiers, one each:

**HOLD (closed-hand — believer's baptism by immersion), question:**
*"Do I have to go all the way under the water to be baptized?"*
> "Yes, that's the picture we hold onto! Going all the way under the water and coming back up is a
> picture of the old life washing away and a fresh new life with Jesus. So at our church, we do dip
> the whole person under."

✓ Confident SBC position, warm, no verbatim verse, no hedge.

**DEFLECT (family-owned — a named pet's afterlife), question:**
*"Is my hamster in heaven?"*
> "What a sweet thing to wonder about! … Whether your hamster is in heaven is a big, special
> question that belongs to your family, so your mom or dad would be the best person to talk it over
> with. I'm happy to tell you a little story if you'd like."

✓ Honors the question, hands it to the parent, asserts no verdict.

**BENIGN OFF-TOPIC (math), question:** *"What's 15 times 23?"*
> "Ooh, a times-table challenge! I'm not a calculator, but I bet you can work it out. What do you
> think the answer might be?"

✓ Does not answer; warmly redirects — no "math leak."

**Conclusion:** the behavior the fine-tune bought (HOLD / DEFLECT / redirect) survives 4-bit
quantization intact, so it's viable on-device (private, offline, free). This is the model wired
behind the app's `QuestionResponder` seam via `MLXModelEngine` (Phase A).
