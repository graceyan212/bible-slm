# Safety, Crisis & COPPA — production readiness

> **This document is engineering + product scaffolding, NOT professional sign-off.**
> A children's app that handles crisis disclosures and collects any data from under-13s
> touches **child-safety** and **child-privacy law**. Two licensed humans must review and
> sign before this ships to real families: (1) a **licensed child-safety / clinical
> professional** (crisis wording + escalation + the "don't assume the parent is safe"
> handling), and (2) **privacy/legal counsel** (COPPA + privacy policy). Nothing below
> substitutes for that. Its job is to make their review fast and concrete.

---

## 1. Current state (what exists today)

| Piece | Status |
|---|---|
| Deterministic danger detector (`SafetyClassifier`) | ✅ built — curated self-harm + abuse phrase list, high-recall by design |
| Model never sees a crisis input | ✅ `GuidedResponder` short-circuits before generation |
| Safe reply text (`crisisReply`) | ✅ no counseling, no secrecy, no probing; urges a trusted grown-up |
| `isCrisis` flag on the response | ✅ (`behaviorClass == .danger`) |
| **Full-screen calm crisis screen** | ❌ not built (P7 spec only) |
| **Escalation: alert a caregiver** | ❌ not built (no notification, no `CrisisEvent`) |
| **Crisis resources (hotlines) surfaced** | ❌ not built |
| **Sanitized crisis event on parent dashboard** | ❌ not built |
| Data stays on-device (no network/analytics) | ✅ so far (`UserDefaults`; no tracking SDKs found) — must be *audited & kept true* |

**Bottom line:** detection + a safe verbal response exist; **escalation and resources do not.**
That gap is the core of this work.

---

## 2. Production crisis-flow design

### 2.1 The four hard invariants (non-negotiable, must be enforced by tests)
The surfaced crisis experience MUST NOT:
1. **Counsel** the child (no advice, no "here's what to do about it").
2. **Promise or imply secrecy** ("this stays between us" is forbidden).
3. **Keep probing** for details (no follow-up questions about the disclosure).
4. Fail to **urge a trusted adult** and (where appropriate) **notify a caregiver**.

These are already encoded as intent in `crisisReply`; production must add an automated test
that fails if any forbidden pattern ever appears in surfaced crisis text (per the P7 spec).

### 2.2 Detection (widen + bound)
- Keep the deterministic phrase gate (never rely on the model for safety).
- **Expand coverage** with a child-safety professional: more kid-register phrasings, and
  categories currently thin (neglect, bullying, a child fearing they did something "bad").
- Accept false positives; a missed disclosure is the only unacceptable error.
- Decide (with the clinician) whether an LLM classifier *adds* recall as a **second layer**
  behind the deterministic gate — but never as the sole gate.

### 2.3 Immediate response (what the child sees)
- A **calm, full-screen, low-stimulation** screen (not Poli being cheerful). Warm, brief,
  age-appropriate: "That's really important. A grown-up who cares about you should know."
- One clear action: **"Show a grown-up"** / hand the device to a trusted adult.
- No chat continuation; the ask loop is paused.

### 2.4 Escalation — and the critical nuance
- **Self-harm / sadness disclosures →** notify the child's caregiver (local notification now;
  a documented APNs/CloudKit path later) + a **sanitized** event on the parent dashboard.
- **⚠️ Abuse disclosures are different.** If the person the app tells the child to "go tell,"
  or the caregiver it alerts, **is the abuser**, naive routing endangers the child. Production
  MUST:
  - Frame the trusted adult **broadly** — "a parent, teacher, school counselor, doctor, or
    another grown-up you trust" — not "your mom or dad."
  - Have the **clinician decide** whether/what to auto-notify a caregiver for abuse-type
    disclosures (this may differ from self-harm handling).
  - Consider surfacing an **independent resource** (see 2.5) that doesn't depend on the home.
- This branch — self-harm vs abuse routing — is the single most important thing the clinical
  reviewer must design and sign. Do not ship a one-size escalation.

### 2.5 Resources (clinician-selected, localized)
- Provide vetted crisis resources. US examples to *propose to the reviewer* (verify + localize):
  **988 Suicide & Crisis Lifeline**; **Childhelp National Child Abuse Hotline 1-800-422-4453**.
- **Placement is a clinical decision:** a 7–9-year-old likely can't call a hotline — resources
  may belong on the **caregiver-facing** screen, with the child-facing screen staying simple
  ("show a grown-up"). Let the reviewer decide child-facing vs caregiver-facing.

### 2.6 Privacy of the crisis event
- Persist only a **sanitized** `CrisisEvent` (whitespace-collapsed, length-capped, a neutral
  category reason — **never the child's raw words**). The notification body carries no transcript.
- Everything stays **on-device** unless/until a reviewed remote-alert path is added.

### 2.7 Recovery
- After the crisis screen, return the child to a **calm, neutral** state (not back into the
  cheerful loop mid-conversation).

---

## 3. Mandatory reporting & legal posture (for counsel)
- Decide the product's **legal status**: is the company/app a *mandated reporter*? (Generally
  mandated-reporter laws target individuals in defined roles, but an app that receives
  disclosures raises questions counsel must answer.)
- Define what the app **can and cannot** promise, and what (if anything) it logs/transmits on
  an abuse disclosure. Document the position in the privacy policy and Terms.
- This is a **legal determination** — flagged for counsel, not decided here.

---

## 4. COPPA & child-privacy checklist
For any app **directed to children under 13** in the US (and analogous: UK Age-Appropriate
Design Code, GDPR-K). Counsel confirms applicability + sufficiency.

- [ ] **Verifiable parental consent (VPC)** before any collection, if data is collected.
- [ ] **Privacy policy** written for the Kids context: what's collected, why, retention,
      sharing (ideally "none"), parent rights (review/delete), contact.
- [x] **Data-handling audit — prove the on-device claim.** _Audited 2026-07-13:_
  - [x] No analytics/telemetry/ads SDKs — **verified none** in `BibleStoryCore` + app target.
        (Add a CI grep guard so a future PR can't introduce one silently.)
  - [x] No child data leaves the device — **verified**: no `URLSession`/network/CloudKit calls;
        wonderings + progress persist to `UserDefaults` (on-device, app-sandboxed).
  - [~] Voice: `SpeechDictation` pins `requiresOnDeviceRecognition = true` **only when
        `supportsOnDeviceRecognition`**. ⚠️ **Harden:** if on-device isn't supported, disable
        voice (type-only) rather than fall back to Apple's server recognition. (One-line change.)
  - [ ] The on-device **model download** (when enabled) transmits **no** child data — will hold
        (it only *downloads* weights), re-verify when the MLX path is turned on.
  - [ ] Consider that `UserDefaults` is unencrypted-at-rest; fine for progress, but keep crisis
        events sanitized (§2.6) and consider the Keychain/encrypted store if anything sensitive lands.
- [ ] **Data minimization & retention:** collect the minimum; define retention/auto-purge for
      wonderings + crisis events; give parents delete.
- [ ] **App Store "Kids" category** requirements: no third-party analytics/ads, parental gate
      for external links/purchases (a biometric/parent gate exists — verify coverage), age band.
- [ ] **App Privacy "nutrition label"** in App Store Connect matches reality.
- [ ] **No behavioral advertising, no data brokering** (Kids category prohibits).
- [ ] **Account model:** if accounts/sync are added later, re-run this whole list — it changes
      the COPPA picture materially.

---

## 5. Human sign-off matrix (what must be signed, by whom)
| Area | Reviewer | Signs off on |
|---|---|---|
| Crisis wording + 4 invariants | Licensed child-safety / clinical professional | The child-facing text never counsels/promises secrecy/probes; tone is safe |
| Escalation design | Same clinician | Self-harm vs **abuse** routing; the "don't assume the parent is safe" branch; whether/what to auto-notify |
| Crisis resources | Same clinician | Which hotlines, child-facing vs caregiver-facing placement, localization |
| Detection coverage | Same clinician | Phrase-list adequacy; whether an LLM second layer is warranted |
| COPPA + privacy policy + Terms | Privacy/legal counsel | Applicability, VPC, policy sufficiency, mandated-reporter position |
| Doctrine (separate track) | SBC-literate theologian | Claim tiering (tracked elsewhere, not this doc) |

---

## 6. Implementation gap → work items (once designs are signed)
Build order (all in `BibleStoryCore` for logic + thin `BibleStory` app glue, per the P7 spec):
1. `CrisisEvent` value type + summary sanitizer (spec'd in P7; tests included there).
2. `CrisisFlowModel` (`@MainActor @Observable`) + `CrisisAlertService` protocol (mockable).
3. Full-screen **calm crisis screen** in the app target; wire it to the ask overlay so any
   `.danger` / `isCrisis` response opens it (fire-toward-safety: either flag opens it).
4. **Caregiver alert** (local notification now) + sanitized `CrisisEvent` on the parent dashboard.
5. **Widen `SafetyClassifier`** per the clinician; add the "forbidden-pattern" invariant test.
6. **Split escalation** by disclosure type (self-harm vs abuse) per the signed design.
7. **Privacy audit + CI guard** (no tracking SDKs; on-device speech pinned).

**Sequencing note:** steps 1–5 can be *built* against the current safe defaults, but the
**text, resources, and escalation branching (3, 4, 6) must not ship until the clinician signs.**
