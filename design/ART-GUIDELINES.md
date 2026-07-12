# Story art guidelines (READ BEFORE GENERATING STORY PAGES)

These rules apply to **all** story-page illustration generation — new stories and fixes.
Image generation always goes through the **TrueFoundry gateway** (OpenAI-compatible;
`IMAGE_*` in `.env`), never a direct provider key.

## 1. Characters must be identical across every page of a story

A recurring character (Jesus, David, Jonah, the prodigal son, etc.) must look the **same
on every page**: same face, hair, beard, skin tone, clothing **colors**, and proportions.
A character whose appearance changes page-to-page (e.g. Jesus bald on one page, bearded on
the next; a robe that switches color) is a defect in a reverent kids' Bible app.

### How
1. **Anchor page.** Choose the best-drawn page for the main character as the canonical
   anchor. Keep it; regenerate the others to match it.
2. **Reference-condition every other page** on the anchor image:
   `client.images.edit(model=<gemini image>, image=[anchor.png], prompt=…, extra_body={"aspect_ratio":"3:2"})`.
   See `design/regen_jesus_children.py` for the working pattern.
3. **Locked character description** in every page prompt. Example (Jesus):
   *long wavy brown hair to the shoulders, short brown beard, warm light skin, calm gentle
   smile, cream/off-white robe with a tan sash belt, brown sandals.* Repeat it verbatim on
   every page so wardrobe/hair never drift.
4. Keep a per-story **character sheet** (a sentence per recurring character) next to the
   story so future regenerations reuse the exact same description.

## 2. Style + framing (unchanged from the existing set)
- Flat children's-storybook cartoon: clean dark outlines, soft watercolor shading, warm.
- **Full-bleed**: the scene fills the frame edge-to-edge, **no cream/paper border, no text**.
  After generating, run `python3 design/trim_story_borders.py` (auto-crops any baked-in
  border; skips already-full-bleed art).
- **3:2 landscape** (aspect_ratio "3:2").

## 3. Doctrine / content
Follow `docs/` behavior-spec: reverent, age 7–9, God-as-hero. Illustrations depict the
retold scene; never add text/labels in the image.
