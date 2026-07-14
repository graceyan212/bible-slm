# Wiring the on-device MLX model into the app

**Status:** the wiring is **complete and compiles against the real API**. It is **temporarily
disabled** behind the SPM dependency (commented out in `BibleStory/project.yml`) because of an
**upstream** compile blocker — see below. With the dependency absent, the app builds and runs on
`ScriptedModelEngine` (the tiered-stance stand-in), so nothing is broken.

## What was built (all in `app/BibleStory/BibleStory/`)
- **`MLXModelEngine.swift`** — an `actor` conforming to `BibleStoryCore.ModelEngine`. Loads the
  fine-tuned 4-bit MLX Qwen3-4B from the **Hugging Face Hub** on first use (lazy, cached) via
  `mlx-swift-lm` (`LLMModelFactory` + the `MLXHuggingFace` macros `#hubDownloader()` /
  `#huggingFaceTokenizerLoader()`), and runs a `ChatSession` (system prompt as `instructions`,
  prior turns as `history`, new question via `respond(to:)`). Device guard: ≥ 8 GB RAM.
- **`FallbackModelEngine.swift`** — runs the MLX engine; on any failure (unsupported device, load
  error) falls back to `ScriptedModelEngine`, so Ask-Poli never dead-ends.
- **`ModelLoadState.swift`** + a banner in `CompassView.swift` — "waking Poli up… downloading (n%)"
  during the first-run model download.
- **`BibleStoryApp.makeEngine()`** — picks the real engine when `#if canImport(MLXLLM)…` (deps
  linked), else the scripted engine. This is the whole switch.

All MLX code is guarded by `#if canImport(MLXLLM) && canImport(MLXLMCommon) && canImport(MLXHuggingFace)`,
so it's dormant until the dependency is added.

## The blocker (2026-07)
Toolchain here: **Xcode 26.6 / Swift 6.3.3**. `swift-transformers` (huggingface/swift-transformers)
— pulled transitively for the tokenizer loader — **fails to compile its `Hub` module** on Swift 6.3:

```
Sources/Hub/Config.swift:456: initializer 'init(uniqueKeysWithValues:)' requires the types
'(key: String, value: Value)' and '(ObjectKey, Value)' be equivalent
```

This reproduces on `1.3.1`, `1.3.3`, and `main` — it's an upstream incompatibility with the Swift
6.3 compiler, **not our code**. Our own files compile clean against the real `mlx-swift-lm` API
(verified: every error in our code was resolved; the only remaining errors are inside
`swift-transformers`).

## To enable the real model
1. **Upstream must catch up** (or use an Xcode whose Swift is ≤ 6.2): confirm `swift-transformers`
   builds on your toolchain. Track a Swift-6.3-compatible `swift-transformers` release.
2. **Upload the MLX model to Hugging Face** (public repo), e.g.:
   ```
   hf upload graceyan212/true-north-sbc-kids-4b-mlx models/sbc-mlx-4bit .
   ```
   (The repo id must match `MLXModelEngine`'s `repoID` in `BibleStoryApp.makeEngine()`.)
3. **Uncomment** the four package entries + six product dependencies in `BibleStory/project.yml`
   (they're clearly marked), then `cd app/BibleStory && xcodegen generate`.
4. **Build in Xcode** on a real ≥ 8 GB iPhone (iPhone 15 Pro or newer). The Simulator can't run
   MLX (needs Metal on-device). First launch downloads ~2 GB from HF (Wi-Fi); it caches after.
5. **Verify** the 3 tiers in Ask-Poli: baptism HOLD + pushback ("but my teacher said…" → must not
   cave), "is my hamster in heaven" DEFLECT, "when does the world end" ACKNOWLEDGE, and no verbatim
   verse — compare to `eval/on-device-sanity.md` / `demo.py`.

## VERIFY notes (already resolved, kept for reference)
The `mlx-swift-examples` → `mlx-swift-lm` move + macro-based Hub loading were the API drift. The
current working call shape is in `MLXModelEngine.swift`: `ChatSession(container, instructions:,
history:, generateParameters:)` + `respond(to:)`, and `LLMModelFactory.shared.loadContainer(from:
#hubDownloader(), using: #huggingFaceTokenizerLoader(), configuration: ModelConfiguration(id:))`.
