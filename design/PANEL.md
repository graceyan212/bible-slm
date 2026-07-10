# STARLIGHT TRAIL — Design Panel Review

*A 3-person panel reviewing the "Starlight Trail" kids' Bible learning app (ages 7–9), viewed as rendered phone screens: `onboarding.html`, `home.html`, `lesson.html`, `compass.html`, plus `tokens.css` and `mascot.svg`.*

**Panel verdict: REVISE** — a genuinely distinctive, thoughtfully-built system with a standout mascot-as-behavior-spec concept. Held back by a handful of concrete, very fixable issues: an inverted trail metaphor, an off-brand "hearts/lives" mechanic, no grown-up/privacy moment at first run, a compass screen that abandons the "Poli is the one button" idea, and a few AA contrast + tap-target misses.

---

## Reviewer 1 — CHILD (age 8) 🧒

*"Honest kid voice."*

| Axis | Score |
|---|---|
| Visual appeal | 9 |
| Kid delight | 8 |
| Clarity | 7 |
| Adventure vibe | 9 |
| Mascot charm | 9 |
| SLM integration | 8 |
| Accessibility (can I use it?) | 8 |
| **Overall** | **8.3** |

**Verdict: PASS**

**What I LOVED**
- The sky is DARK and full of stars and there's a little campfire and a tent — it feels like night-time camping. Whoa.
- The glowy blue star with **START** on it — I know EXACTLY which one to tap. It breathes.
- When I finish the whole unit it *draws a lamb in the stars*?! I want to see all of them.
- Poli is so cute — big eyes, pink cheeks, and it waves at me. The little North-Star on its head wiggles.
- The buttons squish down when I press them like real candy buttons.
- At the end the confetti comets rain down. Do it again!

**MUST FIX (kid complaints)**
- `home.html` — *"Wait, do I go up or down?"* The finished stars are at the top but the campfire that says "you started here" is at the BOTTOM. I got confused which way I'm walking.
- `lesson.html` — *"What are the hearts for? ♥ 4"* Am I going to lose? Did I do something wrong? Nobody told me. It makes me a little worried instead of cozy.
- `compass.html` / `lesson.html` — When I tap Poli I want **Poli** to light up and listen (the head-star spinning!). Right now a different round button does the talking and Poli just sits there. I want Poli to be the one who listens.

---

## Reviewer 2 — PARENT (Christian, of a 7–9yo) 👪

*"Trustworthy, warm, safe, not creepy. Is Poli clearly a helper, not an 'AI friend'? Would I pay?"*

| Axis | Score |
|---|---|
| Visual appeal | 9 |
| Kid delight | 8 |
| Clarity | 7 |
| Adventure vibe | 8 |
| Mascot charm | 8 |
| SLM integration | 7 |
| Accessibility | 8 |
| **Overall** | **7.7** |

**Verdict: REVISE** *(close to pass — trust gaps, not taste gaps)*

**What I LOVED**
- It looks premium and *reverent* — calm twilight, no loud cartoon chaos, genuinely bedtime-appropriate. This doesn't look like a cheap knock-off.
- Poli is framed as a **guide/compass**, not a buddy. The lesson sheet literally says *"Poli tells the story in his own words and always points you back to your Bible."* That's the sentence that makes me trust it.
- The **DEFLECT** behavior is the whole ballgame: I typed "Is my grandpa in heaven?" and instead of an AI answering my child about eternity, Poli warmly hands it to *me* ("a perfect one to talk about with your mom or dad"). That is exactly the boundary I want.
- Retell-not-quote + "read it in *your* family's Bible" respects that Scripture and doctrine are *our* family's job, not a chatbot's.
- The story sits on warm parchment in a big readable font — my early reader can actually read it.

**MUST FIX (trust blockers before I'd pay)**
- `onboarding.html` — First run goes straight into kid choices (avatar, story). There is **no grown-up moment**: no "for parents," no word that audio/questions stay on the device, no biometric parent-gate setup. The trust story exists in your brief but is **invisible** to me, the person deciding to pay. Add a short grown-up/privacy intro at first launch.
- `lesson.html` — The **hearts (♥ 4)** read as a punishment/lives system. For a Bible app you've pitched as calm and non-competitive, a "you can fail / lose lives" mechanic feels wrong and a little stressful for a 7-year-old. Remove it or make it plainly non-punitive.
- `compass.html` — The open **"Ask Poli a question…" text box** is the thing that makes me nervous about kids + AI. The guided-star picker and the deflect logic help a lot, but I'd want the on-device / bounded-to-Bible-stories promise visible right here, next to the input.
- Minor: Poli is repeatedly **"he"/"his."** For a tool I want my kid to see as a helper (not a person/friend), consider "it," or no pronoun.

---

## Reviewer 3 — MASTER kids-app UI/UX designer 🎨

*Duolingo / Khan-Kids caliber. Hierarchy, type, color, the path/node system, mascot-as-system, motion, onboarding, the SLM affordance, accessibility, distinctiveness.*

| Axis | Score |
|---|---|
| Visual appeal | 9 |
| Kid delight | 8 |
| Clarity | 6 |
| Adventure vibe | 9 |
| Mascot charm | 8 |
| SLM integration | 7 |
| Accessibility | 7 |
| **Overall** | **7.7** |

**Verdict: REVISE**

**What I LOVED**
- **Distinctive, not templated.** Grandstander + Lexend instead of the default Fredoka/Baloo, a disciplined 60-30-10 dark palette, and a bespoke SVG mascot. This reads as a *designed world*, not a theme kit.
- **Mascot-as-system is the strongest idea here.** The needle physicalizing HOLD / ACKNOWLEDGE / DEFLECT / CRISIS — making the safety spec a visible, on-brand delight instead of a dead end — is genuinely excellent product thinking. The SVG is authored correctly for it (driveable `#poli-needle`, `#poli-pupils`, etc., with `transform-box: fill-box`).
- **Accessibility is baked in, not bolted on:** node state = color **+ size + icon** (colorblind-safe); body text is 13:1 AAA on the sky (verified); a global `prefers-reduced-motion` kill-switch; and onboarding moves focus to each step's heading and uses `aria-pressed`. The `.btn--danger` even carries a comment showing they *computed* the contrast and rejected white. That's craft.
- The squish/`--shadow-sticker` press, the `--ease-pop` overshoot, the confetti-comet finale, and the parchment reading surface are all well-executed.

**MUST FIX (specific)**
- `home.html` — **The trail metaphor is inverted.** DOM order top→bottom is done → done → done → active → locked → milestone → campfire "you started your trail here." Your own brief says the child *"starts at a little campfire… and climbs a winding trail of stars."* So the campfire (start) must sit at the **bottom** with the earliest lesson, and progress should climb **up** toward the locked/milestone nodes. Right now start and finish are swapped. Reverse the node order (or relocate the campfire). This is core wayfinding.
- `lesson.html` — **Hearts (♥ 4) contradict the brief.** §5 specifies "streak-with-forgiveness, no leaderboards" and "nothing sacred is scored or gamified." A lives mechanic is an off-brand Duolingo import with no quiz to justify it. Remove `.hearts` from the top bar.
- `compass.html` — **The core "Poli = the one tap-to-talk button" concept is broken here.** The voice affordance is a generic teal `🎙️ .mic`; Poli is a static face in the header, and its signature `.is-listening / .is-thinking / .is-answering` states (the whole point of the mascot) never fire on the screen most dedicated to talking to Poli. Make the mic *be* Poli (or add the persistent `.poli-fab` and drive its states). Also reconcile "hold to talk" (brief/idle hint) vs the tap handlers actually wired.
- `lesson.html` — **Tap target below spec.** `.qchip` has no `min-height`; computed height ≈ 34px, under your own 44px floor. Add `min-height: var(--tap-min)`.
- `lesson.html` / `tokens.css` — **AA contrast failures on accents:** kid chat bubble is white on Nebula Violet = **3.72:1** (fails AA normal), and the `.ask-poli::after` "?" badge is white on Comet Pink = **2.27:1** (fails badly); `.badge` shares that pink/white. Switch these to `--outline-ink` text (or darken the fill).
- `home.html`, `lesson.html`, `compass.html` — `<meta viewport … maximum-scale=1>` **disables pinch-zoom** (WCAG 1.4.4). Remove `maximum-scale=1` (onboarding already omits it — match that).
- `lesson.html` — The Ask-Poli bottom sheet is a bare `div.open`: no `role="dialog"`/`aria-modal`, no focus trap, no Escape-to-close, background not inert. Promote it to a real dialog.
- Polish: milestone icon is 🎁 in `home.html` but the spec (§5) says 💎/star; the FAB squeezes a 260×300 SVG into a 64px square (letterboxes Poli smaller than intended — verify legibility at 44–64px); story copy is ~120 words vs the brief's 400–700-word "rich story" target.

**Distinctiveness verdict:** Top-decile concept and world-building; the execution bugs above are what separate it from a shippable Duolingo-caliber build.

---

## Overall Panel Verdict: **REVISE**

Strong, distinctive foundation with a best-in-class mascot concept and real accessibility discipline. Not a redesign — a punch-list. Fix the items below and this is a pass.

### Prioritized fix list (most impactful first)

1. **`home.html` — un-invert the trail.** Put the campfire "start" at the bottom with the earliest lesson and climb upward to the locked/milestone nodes. Core wayfinding + the central adventure metaphor. *(Child + Master)*
2. **`lesson.html` — remove the hearts/lives mechanic (♥ 4).** Off-brand for a calm, non-competitive, "nothing sacred is gamified" product, and unexplained. *(Parent + Master + Child)*
3. **`onboarding.html` — add a grown-up / privacy / parent-gate moment at first run.** Surface the on-device + retell-not-quote + parent-gated promise to the paying parent. *(Parent)*
4. **`compass.html` — make Poli the tap-to-talk button** (or add the persistent `.poli-fab`) and drive its listening/thinking/answering states. Restore the product's core differentiator on the screen that's all about talking to Poli. *(All three)*
5. **Accessibility bundle:** `.qchip` → `min-height:44px` (`lesson.html`); recolor kid bubble + "?" badge + `.badge` to `--outline-ink` (3.72:1 / 2.27:1 fails); remove `maximum-scale=1` from the three inner pages. *(Master; it's the brief's own promise)*
6. **Secondary polish:** add `role="dialog"`/focus-trap/Esc to the lesson Ask-Poli sheet; fix milestone icon 🎁→💎; verify Poli's legibility at 44–64px (FAB letterboxing); reconsider Poli's "he" pronoun; grow story copy toward the 400–700-word target; decide whether the 6 animal onboarding avatars dilute "Poli is your one guide."

---

## Round 2 (post-fix)

*Re-review of the four screens after the round-1 punch-list. All five blocking must-fixes verified against source.*

### Round-1 blockers — status
| # | Item | Status |
|---|---|---|
| 1 | `home.html` trail un-inverted — campfire START at the **bottom**, climb **UP** to the milestone at top (Creation sits by the campfire; lit path runs up to the active node) | ✅ Fixed |
| 2 | `lesson.html` punitive hearts/lives removed — now a non-punitive `✦` star count | ✅ Fixed |
| 3 | `onboarding.html` first-run grown-up / privacy / trust + parent-gate moment (`#grownup-gate`, z-200, shown first) | ✅ Fixed |
| 4 | `compass.html` tap-to-talk button now **is Poli**, driving listening→thinking→answering (teal/violet/gold) states | ✅ Fixed |
| 5 | a11y — `.qchip` ≥44px · kid bubble (≈4.9:1) + "?" badge (≈8:1) recolored to `--outline-ink` (pass AA) · `maximum-scale=1` removed on all pages (pinch-zoom restored) | ✅ Fixed |

### Reviewer 1 — CHILD (age 8) 🧒
| Axis | R1 | R2 |
|---|---|---|
| Visual appeal | 9 | 9 |
| Kid delight | 8 | 9 |
| Clarity | 7 | 9 |
| Adventure vibe | 9 | 9 |
| Mascot charm | 9 | 10 |
| SLM integration | 8 | 9 |
| Accessibility | 8 | 9 |
| **Overall** | **8.3** | **9.1** |

**Verdict: PASS.** *"Now I know I climb UP to the lamb! No more scary hearts. And when I tap Poli, POLI is the one who listens and thinks and answers — the glow changes color!"* All three round-1 kid gripes gone.

### Reviewer 2 — PARENT (Christian) 👪
| Axis | R1 | R2 |
|---|---|---|
| Visual appeal | 9 | 9 |
| Kid delight | 8 | 9 |
| Clarity | 7 | 9 |
| Adventure vibe | 8 | 8 |
| Mascot charm | 8 | 8 |
| SLM integration | 7 | 9 |
| Accessibility | 8 | 9 |
| **Overall** | **7.7** | **8.6** |

**Verdict: PASS** *(was REVISE)*. The first-run grown-up gate finally surfaces the whole trust story before my kid touches anything — on-device, "a guide, not an AI friend," retell-not-quote, my SBC tradition, hard questions handed back to me. That's the sentence that makes it payable. Hearts gone. Only minor nits remain (below), no longer blockers.

### Reviewer 3 — MASTER kids-app UI/UX 🎨
| Axis | R1 | R2 |
|---|---|---|
| Visual appeal | 9 | 9 |
| Kid delight | 8 | 9 |
| Clarity | 6 | 9 |
| Adventure vibe | 9 | 9 |
| Mascot charm | 8 | 9 |
| SLM integration | 7 | 9 |
| Accessibility | 7 | 8 |
| **Overall** | **7.7** | **8.9** |

**Verdict: PASS** *(was REVISE)*. Every headline bug is closed: wayfinding reads correctly, the off-brand lives mechanic is gone, and the core "Poli = the one tap-to-talk button" concept is restored with its listen/think/answer states on the screen that's all about talking to Poli. Contrast, tap-target, and pinch-zoom all fixed. Accessibility held at 8 (not 9) only because one round-1 item is still open (below).

### Panel verdict: **PASS** ✅
All three reviewers pass; the five blocking must-fixes are resolved. A distinctive, trustworthy, shippable-caliber build.

### Remaining must-fix (carry-over — should close before ship, does not block the pass)
- **`lesson.html` Ask-Poli sheet is still not a real dialog.** `.sheet-wrap` has no `role="dialog"`/`aria-modal`, no Escape-to-close, no focus trap, background not inert. This was on the round-1 list and is the only must-fix still open. *(Master)*

### Minor polish (nice-to-have)
- `lesson.html` still says Poli tells it in **"his"** own words; the new grown-up gate uses **"it."** Make it consistent ("it").
- Milestone icon is still 🎁; spec §5 wants 💎/⭐.
- Remove the now-dead `.bar .hearts` CSS rule in `lesson.html`.
- Verb mismatch: lesson sheet says "hold Poli to talk" while compass/home say "tap Poli" — pick one.
- Poli FAB packs the 260×300 SVG into a 64px square (letterboxes to ~55px wide); consider a tighter viewBox or `object-fit` for legibility.
- `.badge` in `tokens.css` still uses white/cream text (fine while it holds an emoji; fix if it ever holds a glyph needing AA).
- Optional: echo the on-device/bounded promise beside the compass text input; grow story copy toward the 400–700-word target.

---

## Post-pass re-skin — "Treasure Trail" (v2 theme, after Grace's vibes PDF arrived)

*The panel above judged the **twilight "Starlight Trail"** skin. After it passed, Grace's inspiration
board finally came through (antique treasure maps, a brass pocket-compass, illuminated storybook
lettering, a handwritten journal, and a caramel · sage · wheat-gold · sand swatch). The app was
**re-skinned to that board** → **"Treasure Trail."***

**What changed:** palette (dark twilight → warm aged parchment), type (Grandstander/Patrick Hand →
**Fraunces** + engraved **Cinzel** map-caps + journal **Caveat**), textures (star-field → faint
compass-rose watermark + dashed X-marks-the-spot route), Poli's face (indigo glass → soft dusty-blue
watercolor), and theme copy (constellation/stars → map/stops/treasure).

**What did NOT change** — so the panel's PASS still stands on these axes: every layout, the
trail-climbs-up wayfinding, the no-hearts decision, the grown-up/parent-gate first-run, Poli-as-the-
one-tap-to-talk-button with its listen/think/answer states, the real `role="dialog"` Ask-Poli sheet,
and all accessibility work (contrast re-verified for the new palette — sepia ink ≈10.9:1 AAA on
parchment; brass/sage CTAs ≈5:1 with dark ink; crisis button flipped to cream text ≈4.7:1; 44px
targets; color+shape+icon states; pinch-zoom; reduced-motion).

**Recommendation:** the re-skin is aligned to Grace's own reference, so it's by-definition on-taste,
and the structural/a11y basis of the pass is untouched. A quick fresh visual glance from the panel is
worthwhile but not blocking — **run it on request.**
