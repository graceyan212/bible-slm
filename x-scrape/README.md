# X (Twitter) scrape — onboarding / paywall research

Collected for the onboarding + paywall design-skill research. One clean text
file per account in [`accounts/`](accounts/); raw gallery-dl JSON in `raw/`.

Each `accounts/*.txt` has a header (@handle, profile URL, tweet count), then
tweets newest-first. Retweets dropped (originals only), media items de-duped,
multi-tweet threads grouped and marked `[THREAD]`. Each entry shows the date,
engagement (♥ likes, ↻ RTs, 💬 replies, 👁 views), and the status URL.

## What was collected (1,550 tweets, ~69k words)

| Role | Account | Tweets | Notes |
|---|---|---|---|
| **Anchor (requirement)** | **@cesaralvarezll** (César Álvarez) | **441** | Dense onboarding/paywall coverage (281 "onboard" / 174 "paywall" mentions) |
| Onboarding | @filippkowalski (Filip Kowalski) | 203 | Dark-pattern / ethics lens |
| Onboarding | @YoniSmolyar (Yoni Smolyar) | 216 | Brainrot builder; worked example |
| Onboarding | @yasirmohiuddin (Yasir Mohiuddin) | 3 | Timeline surfaces almost no original text tweets (mostly RTs/replies) |
| Onboarding | @ZachYadegari (Zach Yadegari) | 0 | **Not retrievable** — see caveat below |
| Paywall/pricing | @athcanft (Will) | 229 | Aggressive paywall pole |
| Paywall/pricing | @alexcooldev (Alex Nguyen) | 217 | Pricing / anti-underpricing |
| Acquisition | @jaxxdwyer (Jax Dwyer) | 119 | Out-of-scope / signal only |
| Acquisition | @LukasPakter (Lukas Pakter) | 7 | Few original text tweets surfaced |
| Acquisition | @adriamatz (Adrià Martinez) | 115 | Out-of-scope / signal only |

## César breakdown corpus (caption + OCR'd screens)

`accounts/cesaralvarezll_BREAKDOWNS.txt` (~49k words) pairs each of César's
tweets with the on-screen text OCR'd from its media, since his step-by-step
teardowns live in the images/videos, not the caption. macOS Vision OCR over
**387 images** (278 with screen text) and **293 sampled frames** from his
**top 14 onboarding/paywall videos by views** (Cal AI, Duolingo, Strava,
Macadam, "$200K/mo hard paywall", etc.). Rolling video-frame text is
de-duplicated. Raw media kept in `media/`, frames in `video_frames/`.

Rebuild: `bash extract_frames.sh && python3 build_cesar_corpus.py`.
Note: OCR includes minor noise (watermarks, clock/status-bar text).

## Method

`gallery-dl` reading a **throwaway** X account's session cookies from Firefox
(X killed all anonymous access in 2024; auth is required). Original tweets only,
text-tweets enabled, paced at 2–2.5s/request. Rebuild with `run_sweep.sh`;
re-convert with `python3 x_to_text.py raw/<handle>.json accounts`.

## Caveats

- **@ZachYadegari returned 0 tweets.** Handle resolves, but timeline, media, and
  `from:` search all come back empty from the throwaway account — meaning the
  throwaway can't see his posts (likely blocked, or his tweets are restricted to
  that account). Retrievable via a different account if needed. He was a
  counter-POV nice-to-have, not a core source.
- **Threads may be truncated to their opening tweet.** The timeline view doesn't
  reliably include self-reply continuations, so some step-by-step breakdowns may
  show only tweet 1. Enable `extractor.twitter.conversations` to pull full
  threads (higher request volume / rate-limit risk).
- **Rate limits.** X throttles timeline reads after ~1,000 tweets in a burst;
  the sweep spaces accounts and can be re-run after the window resets.
