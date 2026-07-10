# Fonts & Color Palettes (concrete design tokens)

All fonts are free on **Google Fonts** under the SIL Open Font License (OFL) unless noted — OFL allows
commercial use, embedding, and **self-hosting** (recommended over the Google CDN for privacy + caching).

---

## Part A — Fonts

### Display / heading (warm storybook, adventure, treasure-map)

**Tier 1 — rounded "storybook" workhorses (best picks):**
| Font | Vibe | Role |
|---|---|---|
| **Fredoka** | Big, round, bubbly, cheerful; the most-recommended kids display font. Variable weight. | Titles, chapter headings, buttons |
| **Baloo 2** | Even plusher/"squeezable"; thick strokes, open counters, confident. | Headlines, logos, buttons |
| **Chewy** | Bouncy, looser, expressive. | Callouts, character dialogue |
| **Sniglet** | Extra-rounded, chubby. | Playful headings, labels |
| **Varela Round** | Soft rounded, very readable; cleaner/less "cartoon." | Heading OR body |

**Tier 2 — bold chunky "punch" (use sparingly, adventure energy):** **Lilita One**, **Titan One**,
**Luckiest Guy** (comic/sticker/badge exclamations), **Cherry Bomb One**, **Grandstander** (variable),
**Paytone One / Carter One**. (**Bungee** = modern/urban, skip for this aesthetic.)

**Tier 3 — "adventure / treasure-map" antique display (map titles/labels ONLY — hurts long-form
legibility):** **IM Fell English** (aged manuscript), **Cinzel** / **Cinzel Decorative** (regal Roman
inscription, uppercase-heavy), **MedievalSharp** (hand-carved fantasy), **Alfa Slab One** (heavy slab).

**Handwriting:** **Patrick Hand** — "written by a friend" tone; good for annotations/captions/narrator.

### Body / reading (early readers, 7–9)

Priority: high x-height, open apertures, rounded-but-clear letterforms, generous spacing, ideally
single-storey **a**/**g** (matches how kids are taught to write).

| Font | Why | Verdict |
|---|---|---|
| **Lexend** ⭐ | Purpose-built for reading proficiency (Dr. Bonnie Shaver-Troup); thesis = **letter spacing + horizontal expansion** drive reading speed. Wide spacing, single-storey a. | **Top body pick.** |
| **Andika** ⭐ | By **SIL**, designed for literacy/beginning readers; single-storey a/g; gives easily-confused letters (b/d) **distinct** shapes to reduce mirror-confusion. | **Strongest literacy-specific pick.** |
| **Nunito** | Rounded-terminal, warm, good x-height. | **Warmest storybook body.** |
| **Atkinson Hyperlegible** | Braille Institute (2021); disambiguates similar chars. | Strong accessibility option. |
| **Quicksand** | Geometric rounded; friendly but better for headings/short text than long body. | Display/labels, not long reading. |
| **OpenDyslexic** | Weighted bottoms; **not** on Google Fonts (self-host); evidence mixed. | Optional user toggle, not default. |

**Evidence caveat (verified):** independent reviewers (W3C; Marinus 2016; Minakata & Beier 2022) find
the measurable benefit is mostly attributable to **letter spacing**, not the specific letterforms or
sans-vs-serif. The widely-quoted Lexend "+19.8% vs Times New Roman" stat is from a **non-peer-reviewed**
educator post. So: Lexend/Andika are well-founded, but much of the benefit comes from **generous
letter-spacing + ≥16px** in any clean rounded font. Treat font choice as one lever, not a magic fix.

### Recommended pairings

- **Warmest storybook (safest all-rounder):** **Fredoka** (display) + **Nunito** (body)
- **Max literacy:** **Baloo 2** (display) + **Lexend** or **Andika** (body)
- **Treasure-map / epic layer:** **Cinzel** or **MedievalSharp** or **Alfa Slab One** (map titles ONLY)
  + **Lexend** (body); a warm literary serif like **Lora** also works for atmospheric body.
- **Comic / Dog-Man energy + max readability:** **Chewy**/**Luckiest Guy** (display) + **Lexend** (body)

Set body **≥16px** with slightly increased letter/line spacing.

---

## Part B — Color palettes (real hex)

Role labels: **BG** background · **Primary** dominant · **Accent** secondary pop · **Highlight**
rewards/progress/CTA · **Text** (avoid pure black — use deep navy/teal/slate).

### Palette A — "Warm Parchment / Treasure Map" (recommended hero direction)
| Role | Hex | Name |
|---|---|---|
| BG (aged paper) | `#F4E4C1` | Parchment |
| Deeper paper/panels | `#E8D4A0` | Aged Vellum |
| Text / ink | `#4A3520` | Sepia Ink |
| Primary accent | `#1F6F6B` | Deep Teal (sea/map) |
| Highlight / gold | `#E0A526` | Treasure Gold |
| Marker / "X" / alert | `#C0392B` | Compass Red |
| Deep accent | `#2C3E50` | Navy Compass |

*Alt parchment set:* BG `#F1E9D2`, candlelit `#F2DCA7`, cinnamon primary `#D47E30`, antique gold
`#C8A24B`, worn-edge brown `#8C7A70`. Design tip: darker shades on edges = worn/aged look; gold reserved
for the "X marks the spot."

### Palette B — "Adventure Storybook" (warm, rich, cinematic — Pixar/Moana warmth)
| Role | Hex | Name |
|---|---|---|
| BG (cream) | `#FDF6E3` | Warm Cream |
| Primary | `#F28C38` | Sunset Orange |
| Secondary | `#4E7C59` | Forest Green |
| Accent | `#3D5A80` | Dusk Blue |
| Warm secondary | `#C65D3B` | Terracotta |
| Deep text | `#3A2E28` | Cocoa |
| Berry pop | `#9B2226` | Berry |

*Classic "storybook kids" variant:* cream `#F4F1DE`, terracotta `#E07A5F`, deep teal `#3A7CA5`, sage
`#81B29A` (progress/"found it!" only), deep navy text `#3D405B`.

### Palette C — "Bright Friendly" (Duolingo/Toca energy) — **verified Duolingo brand hex**
| Role | Hex | Name |
|---|---|---|
| BG | `#FFFFFF` / `#F7F7F7` | Snow / Polar |
| Primary (go/correct) | `#58CC02` | Feather Green |
| Primary shade | `#89E219` | Mask Green |
| Accent | `#1CB0F6` | Macaw Blue |
| Highlight | `#FFC800` / `#FF9600` | Bee Yellow / Fox Orange |
| Play/magic | `#CE82FF` | Beetle Purple |
| Alert | `#FF4B4B` | Cardinal Red |
| Text | `#4B4B4B` | Eel |

---

## Part C — Accessibility / contrast for kids (verified vs. WCAG)

- **Target AAA where feasible:** AA = 4.5:1 normal / 3:1 large; **AAA = 7:1 / 4.5:1**. Design **body
  text to 7:1** for young/low-vision readers.
- **Interactive elements** (buttons, icons, borders): **≥3:1** vs. adjacent color (WCAG 1.4.11).
- **Never rely on color alone** (1.4.1) — pair color with icon/text/shape (colorblind-safe correctness).
- **Don't round up:** `#777777` (4.47:1) fails 4.5:1 — verify with the WebAIM checker.
- **Body ≥16px.** Replace pure black type with deep navy/teal/slate (`#3D405B`, `#4A3520`, `#4B4B4B`).
- **Structure 60-30-10:** ~60% light neutral BG, ~30% dominant hue, ~10% accents; keep to **4–6 core
  colors**; let big shapes carry saturation, keep body text on light neutrals.
- **Contrast flags:** terracotta/sage/gold/teal/feather-green **fail as small text** on light BGs — use
  them as fills/icons/large titles, with the dark ink color for body copy.

Sources: https://fonts.google.com/ · https://www.lexend.com/ · https://software.sil.org/andika/ · https://design.google/library/lexend-readability · https://www.brailleinstitute.org/freefont/ · https://design.duolingo.com/identity/color · https://webaim.org/articles/contrast/ · https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html · https://lospec.com/palette-list/treasure-map-paper-color
