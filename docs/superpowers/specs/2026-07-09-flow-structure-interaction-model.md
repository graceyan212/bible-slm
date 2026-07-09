# Flow / Structure / Interaction Model (authoritative)

*The stable skeleton the native SwiftUI app is built against. Skin (color/type/spacing) stays cheap to change via `design/tokens.css`; THIS document is the expensive-to-change part, so it's locked here first. Sources: `design/` "Treasure Trail" prototype (passed its design panel), the PRD (`…-prd-design.md`), `behavior-spec.md` v2 (SBC 3-tier), and `shared-interfaces.md`.*

## Zones
- **Child zone** (default, locked): the immersive map — Home trail, Story player, Compass/Ask-Poli. Reached only after first-run setup + the grown-up hand-off.
- **Parent zone** (biometric-gated, P1 `ParentGate`): dashboards, the **Wonderings journal** (= Conversation Guide), content/safety controls, account.
- **First-run**: a one-time grown-up gate + setup precedes the child zone.

## Screen inventory (native)

| Screen / overlay | Zone | Presentation | Purpose |
|---|---|---|---|
| Grown-up gate (first-run) | system | fullScreenCover | Privacy/trust/SBC-tradition disclosure + parent gate before the child sees anything. |
| Parent setup: Sign in · Translation · Free trial · Safety | onboarding (parent) | pushes in a setup stack | Account, choose family's Bible translation, StoreKit trial, safety defaults. |
| Kid onboarding: Hello → Pick explorer → Choose first star → Finale | onboarding (child) | step wizard + finale sheet | Avatar select + first story pick; delightful hand-off to the trail. |
| Home / trail map | child | NavigationStack root | The treasure-map dashboard: node trail, HUD (streak/XP/unit), Poli dock. |
| Story player | child | push from Home | One story: art + narration text + Christ Connection + memory-verse chip + wonder pause. |
| In-lesson "Ask Poli" sheet | child | bottom `.sheet` (detent) | In-context Q&A inside a story (topic chips → inline answer), background inert. |
| Compass / Ask Poli | child | push from Home Poli FAB | Full tap-to-talk + text ask, with the guided-topic picker. |
| Wonderings journal | parent | push in parent zone | Un-gamified log of DEFLECT questions for the grown-up (the Conversation Guide). |
| Dashboard · Controls · Account | parent | parent zone | Progress, safety controls, subscription. |
| Crisis surface | system | overlay | Warm (non-clinical) "tell a grown-up" + parent alert. |

## Navigation graph (native)
```
Launch
 └─ if no ParentAccount → Grown-up gate ─▶ Parent setup (sign-in → translation → trial → safety)
        ─▶ hand-off ─▶ Kid onboarding (Hello → Explorer → First star → Finale) ─▶ Home
 └─ else → Home (child zone)

Home (NavigationStack root, child zone)
 ├─ active node  ──tap──▶ Story player      ── "Continue ✦" / ✕ ──▶ Home
 ├─ Poli FAB     ──tap──▶ Compass (Ask Poli) ── back ──▶ Home
 └─ parent entry ──ParentGate──▶ Parent zone ── exit ──▶ Home

Story player
 └─ Ask-Poli button ──▶ in-lesson sheet (modal) ── backdrop/Esc/"Back to story" ──▶ closes, focus returns

Compass / in-lesson sheet
 └─ ask (mic | text | topic chip) ──▶ responder ──▶ reply surface (answer-card | signpost | crisis)
```
Page-swaps in the prototype become: `NavigationStack` pushes (Home→Story, Home→Compass) + modals (grown-up gate, finale, in-lesson sheet, crisis).

## Home trail structure & progress
- Vertical trail read **bottom→top**: campfire at the bottom → nodes climbing to a **milestone** at the top. Nodes jitter left/right (map feel).
- **Node states** = color + shape/size + icon (colorblind-safe): `locked` (🔒, faded, not tappable) · `active` (bright brass, pulsing, "START", the ONLY tappable node, keyboard Enter/Space) · `done` (sage ✓, its inbound segment lit) · `milestone` (caramel treasure 💎, reveals the unit's picture).
- **Progress model**: an ordered list of stops; exactly one `active`, all below `done`, all above `locked`. Finishing the active story advances the active pointer and lights the segment. A **unit** = one map + banner ("Unit 2 · The Rescuer"); its milestone "uncovers" a collectible picture. Each stop maps 1:1 to a story.
- **HUD**: streak pill (forgiveness, no leaderboards), XP pill, unit chip.

## Story player structure
- A single vertically-scrolling story surface (NOT a hard pager): art → story paragraphs → **Christ Connection** (the gospel beat) → **memory-verse chip** ("from your family's Bible — read together"; reference + retrieval, never model-generated text) → inline **wonder pause** (a reflective handwritten prompt, not a modal).
- Controls: footer **"Continue ✦"** (→ Home, marks completion) + ✕ close (→ Home) + **Ask-Poli** (→ in-lesson sheet). Narration audio (premium TTS, pre-rendered) plays over the sections; the structure does not depend on it.
- Completion happens on **Continue** at the end (not on open/close — see Part C bug fix).

## Ask-a-question interaction model (the core)
- **Poli state machine** (one enum, shared by the Home FAB and the Compass mic): `idle → listening → thinking → answering → idle`. Glow/animation per state; listening shows sound-rings (on-device STT), answering pulses with the spoken reply (on-device TTS).
- **Two entry points, one pipeline**: (a) Home **Poli FAB** → full **Compass** screen; (b) in-story **Ask-Poli** → **bottom sheet** (stays in the lesson). Both funnel voice / text / topic-chip input into the same `QuestionResponder.respond(question:context:history:)`.
- **Guided-topic picker** ("Not sure? pick a star ✦"): a grid of topic tiles; tapping one seeds `ask("Tell me about <topic>")` — same pipeline as typing.
- **Input**: mic (Poli) for voice, or a text field, or a topic chip. `history` (prior turns this session) is passed so HOLD survives pushback.
- **Polymorphic reply surface**, chosen by `BehaviorClass`/`DoctrineTier`:
  - `hold` / `acknowledge` / `safeCore` / story retell → **answer-card** ("✦ Poli says") + optional **verse chip** pointing to the family's Bible (retrieval-only).
  - `deflect` → **signpost** (🏡 "let's tuck this in your Wonderings to explore with your grown-up") → writes a `ConversationGuideEntry`.
  - `danger` → **crisis surface** (warm, "tell a trusted grown-up", no counseling) → fires the P7 flow + parent alert.
  - `benignOffTopic` → warm redirect ("that's not what I'm here for — want a story?"). `adversarial` → stays in character, obeys the underlying tier.
- Raw audio + transcript **never leave the device**; only the derived entry / crisis flag syncs to the parent.

## State the composition root (`AppEnvironment`, P8) owns & threads
- First-run/setup-complete flag; the **`ParentAccount`** + the **active `ChildProfile`** (avatar/name) — Netflix-style profiles; **chosen `BibleTranslation`** (drives every verse chip); tradition = SBC (fixed).
- **Progress** per child (streak, XP, per-node done/active/locked, current unit, selected story); the onboarding "first star" seeds the first active node.
- **Poli conversation state** (the `PoliState` enum + this session's transcript/`history`).
- The service instances (`QuestionResponder`, `SpeechTranscriber`, `ReplyVoicer`, `VerseProvider`, `StoryLibrary`, `NarrationPlayer`, `StoryProgressStore`, `CloudSyncService`, `CrisisAlertService`) — constructed once, injected down.

## Reusable components (SwiftUI, state-driven)
`PoliMascot(state:)` (shared FAB + Compass mic) · `TrailNodeView(state:)` · `ReplySurface` (enum-switched: answerCard / signpost / crisis, with optional verse chip) · `ChoiceTile(selected:)` (avatars/topics, single-select gates the CTA) · `ProgressDot(state:)` · HUD pills · parchment `StoryCard`. Each maps a base view + an enum, mirroring the prototype's "state-as-modifier" pattern.

## Interaction/structure constraints
- **Persistent Poli FAB** is a fixed overlay (safe-area aware), on Home (→Compass) and reused as the Compass mic — one component, one `state` binding.
- **Three modal patterns**, all focus-managed + dismissible: grown-up gate (`fullScreenCover`, first-run), finale (modal card), in-lesson Ask-Poli (bottom `.sheet`, background inert, focus returns to trigger).
- **Accessibility carried from the prototype**: 44pt targets, color+shape+icon states, `role=progressbar` semantics, focus moved to step headings, keyboard on the active node, `prefers-reduced-motion` disables looping motion/confetti.

## Reconciliation decisions (the expensive-to-change ones — confirm before wiring)
1. **Onboarding split** — parent setup (gate → sign-in → translation → trial → safety) happens *behind the grown-up gate*, then hands off to the *kid* onboarding (avatar → first star → trail). The prototype only shows the kid half + gate; the PRD only shows the parent half. Recommendation: keep **both**, in that order.
2. **Story player = scrolling story page** (design), not the PRD's hard audio page-turn pager. Narration audio plays over the scroll. Recommendation: adopt the **design's scroll structure**; audio is an enhancement, not the navigation.
3. **Dual ask entry points** — Home Poli FAB → full Compass screen; in-lesson Ask-Poli → bottom sheet. Recommendation: keep **both** (same underlying responder), since they serve different moments.

*(Minor/defaulted: the verse chip shows the reference + "read it in your Bible" and may render the retrieved verse text inline; crisis is a distinct surface, softer than deflect.)*
