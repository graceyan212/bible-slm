#!/usr/bin/env python3
"""Extend the cropped ExpeditionMap into a taller (~2.3-screen) scrollable canvas.

Approach (composite, no network): sample a same-tone parchment base from the
original and blur it so it reads as aged paper, then paste real hand-drawn
sepia FEATURES (mountains, forests, dunes, temple, coastline) cut from the
original with a feathered alpha so there are NO visible rectangular seams.
Mountains stay at the TOP (the start), the compass rose + ship + treasure
chest stay near the BOTTOM (the destination), and the tan nav shelf strip is
pinned to the very bottom (it sits behind the pinned wood nav bar).
"""
import numpy as np
from PIL import Image, ImageFilter

SRC = "docs/design-assets/expedition-map-cropped.png"
OUT = "app/BibleStory/BibleStory/Assets.xcassets/ExpeditionMap.imageset/expedition-map-tall.png"
OUT_COPY = "docs/design-assets/expedition-map-tall.png"

src = Image.open(SRC).convert("RGB")
W, H = src.size                      # 656 x 1291
TARGET_H = 5900                      # ~9x wide → fits 12 well-spaced stops

def feather_mask(w, h, pad=55):
    """Soft alpha: opaque center, linear fade to 0 over `pad` px at every edge."""
    ys = np.minimum(np.arange(h), np.arange(h)[::-1])
    xs = np.minimum(np.arange(w), np.arange(w)[::-1])
    fy = np.clip(ys / pad, 0, 1)
    fx = np.clip(xs / pad, 0, 1)
    m = np.minimum(fy[:, None], fx[None, :])
    return Image.fromarray((m * 255).astype("uint8"), "L")

def paste(canvas, box, dest, pad=55, opaque=False):
    crop = src.crop(box)
    if opaque:
        canvas.paste(crop, dest)
    else:
        canvas.paste(crop, dest, feather_mask(crop.width, crop.height, pad))

# --- Parchment base: a full-width band, mirror-tiled then blurred to a smooth
#     aged-paper tone that matches the original everywhere (kills features). ---
band = src.crop((0, 300, W, 620))          # 656 x 320 mid band
strip_h = band.height
base = Image.new("RGB", (W, TARGET_H))
y = 0
flip = False
while y < TARGET_H:
    piece = band.transpose(Image.FLIP_TOP_BOTTOM) if flip else band
    base.paste(piece, (0, y))
    y += strip_h
    flip = not flip
base = base.filter(ImageFilter.GaussianBlur(38))   # dissolve any residual features

canvas = base.copy()

# --- Real hand-drawn features, feathered so light paper edges melt into base ---
# Top of the map: the full mountain range + ruined temple (the "start").
paste(canvas, (0, 0, W, 360), (0, 0), pad=70)

# Scatter terrain down the winding middle (alternating sides), reusing the
# original's mountains / forests / dunes / temple so the style is identical.
paste(canvas, (0, 590, 250, 880),   (0, 470))       # left forest belt
paste(canvas, (400, 560, W, 760),   (395, 560))      # right dunes
paste(canvas, (420, 660, W, 900),   (400, 820))      # right snowy mountains
paste(canvas, (290, 760, 540, 930), (240, 1080))     # center forest
paste(canvas, (0, 600, 200, 830),   (70, 1360))      # left forest again (lower)
paste(canvas, (430, 200, 640, 330), (30, 1600), pad=45)   # a temple landmark
paste(canvas, (400, 560, W, 720),   (330, 1720))     # dunes
paste(canvas, (0, 660, 230, 900),   (0, 1980))       # forest + coastline
paste(canvas, (420, 660, W, 900),   (400, 2120))     # snowy mountains
paste(canvas, (290, 760, 520, 920), (120, 2360))     # center forest cluster
paste(canvas, (0, 100, 220, 340),   (410, 2430), pad=45)  # mountains near the goal

# Extended middle (TARGET_H bumped 3150 → 5900): keep the added length lively by
# scattering the same hand-drawn crops down y=2560..5300, alternating sides so it
# never reads as a repeated stamp or a blank parchment stretch.
paste(canvas, (400, 560, W, 720),   (330, 2560))     # right dunes
paste(canvas, (0, 590, 250, 880),   (0, 2740))       # left forest belt
paste(canvas, (290, 760, 520, 920), (200, 2980))     # center forest cluster
paste(canvas, (420, 660, W, 900),   (400, 3160))     # right snowy mountains
paste(canvas, (0, 660, 230, 900),   (0, 3400))       # left forest + coastline
paste(canvas, (430, 200, 640, 330), (430, 3470), pad=45)  # right temple landmark
paste(canvas, (400, 560, W, 760),   (340, 3660))     # right dunes
paste(canvas, (290, 760, 540, 930), (110, 3880))     # center forest
paste(canvas, (420, 660, W, 900),   (400, 4120))     # right snowy mountains
paste(canvas, (0, 600, 200, 830),   (40, 4300))      # left forest
paste(canvas, (430, 200, 640, 330), (30, 4520), pad=45)   # left temple landmark
paste(canvas, (400, 560, W, 720),   (330, 4640))     # right dunes
paste(canvas, (290, 760, 520, 920), (170, 4860))     # center forest cluster
paste(canvas, (420, 660, W, 900),   (400, 5040))     # right snowy mountains
paste(canvas, (0, 660, 230, 900),   (0, 5220))       # left forest + coastline

# Bottom of the map: compass rose + ship + treasure chest (the "destination").
dest_band = (0, 900, W, 1200)
paste(canvas, dest_band, (0, TARGET_H - 91 - (1200 - 900)), pad=80)

# The tan nav shelf strip, pinned flush to the very bottom (sits behind nav bar).
paste(canvas, (0, 1200, W, H), (0, TARGET_H - (H - 1200)), opaque=True)

# --- Gentle edge vignette for depth (matches the original's aged look) ---
vig = Image.new("L", (W, TARGET_H), 0)
vx = np.minimum(np.arange(W), np.arange(W)[::-1]) / (W * 0.22)
vy = np.minimum(np.arange(TARGET_H), np.arange(TARGET_H)[::-1]) / (W * 0.22)
vv = np.clip(np.minimum(vx[None, :], vy[:, None]), 0, 1)
vig = Image.fromarray(((1 - vv) * 60).astype("uint8"), "L")
shade = Image.new("RGB", (W, TARGET_H), (90, 66, 38))
canvas = Image.composite(shade, canvas, vig)

canvas.save(OUT)
import os
os.makedirs("docs/design-assets", exist_ok=True)
canvas.save(OUT_COPY)
print(f"wrote {OUT} ({canvas.size[0]}x{canvas.size[1]})")
