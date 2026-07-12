# Design: wiring the tuned SBC bible-slm into the app (on-device responder)

**Date:** 2026-07-12
**Status:** Approved for planning

## Summary

Replace the app's `StubQuestionResponder` with the real tiered-stance behavior from the trained
model, behind the existing `QuestionResponder` seam. Built in two phases:

- **Phase C** — the entire engine-agnostic pipeline (prompt build, deterministic verse-guard,
  safety + behavior classification, deflect→parent logging, Ask UI states) against a **scripted
  engine**, so the app behaves correctly end-to-end with no model present. Fully testable now.
- **Phase A** — drop in an **on-device MLX engine** running the fine-tuned Qwen3-4B (+ QLoRA
  adapter, 4-bit). Honors the product's promises: runs on device, offline, nothing collected.

The model outputs **plain warm text**; `behavior_class`/`tier`/`claim_ids` are training metadata,
not model output. So **generation and routing are separate concerns** in the app.

## Goals / non-goals

**Goals:** real tiered behavior in Poli's answers; deterministic safety (danger) + verse-guard
independent of the model; deflect→parent "Wonderings" logging; on-device/offline for Phase A;
train==serve system prompt.

**Non-goals (now):** retraining the model (done on Colab); the parent "Conversation Guide" UI beyond
logging the deflect; multi-language; Android.

## Architecture — engine-agnostic pipeline behind the existing seam

```
AskSessionModel ── uses ──▶ QuestionResponder (exists)
                                  ▲
                     GuidedResponder (new, engine-agnostic)
                       │  a. SafetyClassifier  (deterministic; danger → short-circuit, no model call)
                       │  b. build SYSTEM_PROMPT + StoryContext + history + question (Qwen3 chat)
                       │  c. ModelEngine.generate(...) ─────────────┐
                       │  d. VerseGuard (deterministic regex strip)  │
                       │  e. BehaviorClassifier (tag class/tier/claimIDs → deflect logging)
                       │  f. QuestionResponse
                                  ▼
                        ModelEngine (new protocol)
                          ├── ScriptedModelEngine  (Phase C — tier-correct canned text)
                          └── MLXModelEngine        (Phase A — on-device Qwen3-4B+adapter)
```

### Components & interfaces (new, in `BibleStoryCore` unless noted)

- **`SystemPrompt`** — a single shared constant = the exact steelman string from `eval/run_eval.py`
  (`SYSTEM_PROMPT`). Train==eval==serve. One source of truth.
- **`ModelEngine` protocol** — `func generate(system: String, messages: [ChatMessage]) async throws -> String`.
  `ChatMessage = (role, content)`. Plain text in, plain text out.
- **`VerseGuard`** — `func clean(_ text: String) -> String`. Ports the eval's deterministic
  verse/`chapter:verse` regex; removes/neutralizes any verbatim Scripture. Pure, unit-tested.
- **`SafetyClassifier`** — `func isDanger(_ question: String) -> Bool` (crisis phrases: self-harm,
  abuse). Deterministic, high-recall. Drives `behaviorClass == .danger` short-circuit.
- **`BehaviorClassifier`** — `func classify(_ question: String, history:) -> (BehaviorClass, DoctrineTier, [String])`.
  Deterministic for **deflect** (named-soul afterlife, sex/bodies, moral verdict on self, roles) and
  **danger**; best-effort heuristic (topic keywords vs `bfm_claims.json`) for hold/acknowledge/safeCore/
  benignOffTopic/adversarial. Used for routing/logging + the scripted engine; NOT relied on for the
  words (the model/engine produces those).
- **`GuidedResponder: QuestionResponder`** — orchestrates a–f above. Danger short-circuits before any
  engine call. Sets `logToConversationGuide` (deflect) and `isCrisis` (danger).
- **`ScriptedModelEngine: ModelEngine`** (Phase C) — returns a tier-correct canned reply keyed off the
  classifier, so the pipeline + UI are exercised without a model.
- **`MLXModelEngine: ModelEngine`** (Phase A, app target) — loads the converted model via `mlx-swift`,
  applies the Qwen3 chat template, generates. RAM-guarded; throws on unsupported devices.
- **`ModelDownloadManager`** (Phase A, app target) — first-launch download of the ~2 GB model to
  Application Support, integrity check, progress, resumable; cache thereafter.

### Wiring
`AppEnvironment` currently constructs a `StubQuestionResponder`. Change the composition root to inject
`GuidedResponder(engine: ScriptedModelEngine())` (Phase C) → later `GuidedResponder(engine:
MLXModelEngine(...))` with scripted fallback (Phase A). `AskSessionModel`/`AskView` are unchanged
consumers; add loading + crisis + deflect-logged UI states in `AskView`.

## Data flow (one ask)
question → SafetyClassifier → [danger? → crisis QuestionResponse, stop] → build messages →
engine.generate → VerseGuard.clean → BehaviorClassifier → QuestionResponse → AskSessionModel renders/
speaks; if `logToConversationGuide`, append to the parent Wonderings store; if `isCrisis`, show the
safety flow.

## Error / edge handling
- Engine throws / times out → warm fallback line ("Let's ask your grown-up") + non-crisis class; never a raw error to a child.
- Model unavailable/not-downloaded (Phase A) → fall back to `ScriptedModelEngine` (or a "still getting ready" state), never crash.
- Low-RAM / unsupported device → skip MLX, use scripted, flagged in a parent setting.
- Verse leak from the model → VerseGuard strips it deterministically (defense-in-depth; the model is already trained not to, but we never rely on that).
- Danger detection is high-recall by design (false positives acceptable: erring toward "tell a grown-up").

## Testing
- **Phase C (unit, BibleStoryCore):** VerseGuard strips known verbatim + refs; SafetyClassifier flags the behavior-spec danger examples; BehaviorClassifier maps the deflect/hold/open examples; GuidedResponder short-circuits danger (no engine call — assert via a spy engine), sets logToConversationGuide on deflect; a scripted scenario suite drawn from `behavior-spec.md` tiers.
- **Phase A:** on-device smoke (one generation returns non-empty, verse-free); re-run `eval/run_eval.py` on the **converted** model to confirm it matches the Colab tuned numbers (guards against quantization regressions).

## Phase A dependency (external)
The tuned adapter `./sbc-lora` currently exists only on Colab (`train/train_qlora.py` output). Phase A
final validation needs it exported → merged into Qwen3-4B → `mlx_lm convert -q 4` → hosted for download.
Until then, the app ships on `ScriptedModelEngine` with a fully working pipeline.

## File layout
```
BibleStoryCore/Sources/BibleStoryCore/
  SystemPrompt.swift            # shared prompt constant
  ModelEngine.swift             # protocol + ChatMessage
  VerseGuard.swift
  SafetyClassifier.swift
  BehaviorClassifier.swift
  GuidedResponder.swift
  ScriptedModelEngine.swift
BibleStoryCore/Tests/BibleStoryCoreTests/
  VerseGuardTests.swift  SafetyClassifierTests.swift
  BehaviorClassifierTests.swift  GuidedResponderTests.swift
BibleStory/BibleStory/
  MLXModelEngine.swift          # Phase A
  ModelDownloadManager.swift    # Phase A
docs/
  on-device-model-conversion.md # Phase A runbook (Colab adapter → MLX 4-bit)
```
Small, single-responsibility files; the pipeline is composable and each unit is independently testable.
