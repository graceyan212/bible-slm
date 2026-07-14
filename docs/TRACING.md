# Observability & beta feedback

How to see what Poli does, catch what goes wrong, and iterate from the church beta — **without**
breaking the on-device privacy design.

## The model (important)
Your app runs the model **on the device** (Swift), not as a Python/cloud agent. So the
`@traceable`-decorator + LangSmith pattern from the lecture (which instruments Python functions)
**does not apply directly**. Instead we capture a structured **trace per interaction** in-app and,
for the beta only, **export** it to an observability platform over HTTP.

## What's built
- **`InteractionTrace`** (`BibleStoryCore`) — one record per ask: anonymous `sessionID`, the
  question, the chosen `behaviorClass`/`tier`, `crisisFired`/`deflected` flags, Poli's output,
  latency, `modelVersion`, and a `feedback` (👍/👎). **De-identified — never a name.**
- **`LocalTraceStore`** — records every interaction **on-device** (capped, persisted), exposes
  `traces`, `thumbsDown`, and `exportJSON()`. This is the production-safe default.
- **`Tracer`** protocol + **`NoOpTracer`** — so tests/production can record nothing.
- **Wiring:** `AskSessionModel` records a trace on every answer; `AppEnvironment.traceStore` owns
  the log; the Ask screen shows a grown-up **👍/👎** on each answer (`session.rate(...)`).
- **`LangFuseExporter`** (app target) — the **consent-gated** exporter that POSTs de-identified
  traces to a (preferably self-hosted) LangFuse. It is the single reviewed exception to the
  privacy guard and is **not** wired into normal flow — a beta screen calls `upload(...)`.

## Privacy posture
- **Production default:** on-device only. `scripts/privacy-audit.sh` fails the build if any
  network/tracking call appears — except the one reviewed `LangFuseExporter.swift`.
- **Beta:** with **signed parental consent** (`docs/PARENTAL-CONSENT-BETA.md`), export traces to a
  **self-hosted** LangFuse you control. De-identified (anonymous `sessionID` only).

## Running the church beta
1. Collect a signed consent form per child.
2. Stand up **self-hosted LangFuse** (Docker) and create a project → get `publicKey`/`secretKey`.
3. In a beta build, gate export behind a consent flag and call:
   ```swift
   let exporter = LangFuseExporter(config: .init(host: URL(string: "https://your-langfuse")!,
                                                  publicKey: "pk-…", secretKey: "sk-…"))
   try await exporter.upload(env.traceStore.traces)
   ```
4. In LangFuse, filter for **👎** and **`crisisFired` / mis-tiered** traces — those are your
   highest-signal failures.
5. Feed the real questions + the 👎 cases back into the dataset (`data/`) and re-run
   `eval/run_eval.py` → the improvement loop.

## Note on the model
Until the on-device model is unblocked (see `app/MLX-SETUP.md`), traces reflect the **scripted**
Poli (`modelVersion: "scripted"`). That still validates tiers, crisis detection, latency, and the
app flow. Set `AppEnvironment.modelVersion` when the real model goes live so traces label it.
