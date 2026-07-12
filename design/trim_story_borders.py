#!/usr/bin/env python3
"""Trim the baked-in cream margin + hand-drawn frame line off story PAGE art so
the illustration bleeds edge-to-edge in the reader.

The Nano-Banana art was generated with a "sketchbook" border: a cream paper
margin, then a dark ink frame line, then the scene. The reader shows the art
full-width, so that cream margin appears as white side-borders. This trims to
the scene. Safe for already-full-bleed images: if no uniform light margin is
detected on an edge, that edge is left alone (0 trim).

Targets every  Assets.xcassets/Story*P<N>.imageset/*.png  (reader page art; the
new stories reuse P1 as their cover, so covers get cleaned up too). Idempotent-ish
within a small tolerance; re-running trims ~nothing once borders are gone.
"""
import glob, os, re
import numpy as np
from PIL import Image

ASSETS = "app/BibleStory/BibleStory/Assets.xcassets"
PAGE_RE = re.compile(r"/Story[A-Za-z]+P\d+\.imageset/[^/]+\.png$")

TOL = 42          # RGB distance from the corner cream still counted as "margin"
MARGIN_FRAC = 0.90  # a line is "margin" if >=90% of its pixels are near-cream
FRAME_INSET = 0.014 # after the cream, drop this frac of the dim to kill the ink frame
MAX_TRIM = 0.12     # never trim more than 12% off a side (safety against runaway)

def near(arr, color):
    d = np.sqrt(((arr.astype(int) - color.astype(int)) ** 2).sum(-1))
    return d < TOL

def margin_count(mask_line):
    return mask_line.mean()

def trim_one(path):
    im = Image.open(path).convert("RGB")
    a = np.asarray(im)
    h, w, _ = a.shape
    # cream reference = mean of the four 8x8 corners
    corners = np.concatenate([
        a[:8, :8].reshape(-1, 3), a[:8, -8:].reshape(-1, 3),
        a[-8:, :8].reshape(-1, 3), a[-8:, -8:].reshape(-1, 3)])
    cream = corners.mean(0)
    mask = near(a, cream)  # True where near-cream

    def scan(get_line, n, limit):
        i = 0
        while i < limit and margin_count(get_line(i)) >= MARGIN_FRAC:
            i += 1
        return i

    top    = scan(lambda i: mask[i, :],      h, int(h * MAX_TRIM))
    bottom = scan(lambda i: mask[h-1-i, :],  h, int(h * MAX_TRIM))
    left   = scan(lambda i: mask[:, i],      w, int(w * MAX_TRIM))
    right  = scan(lambda i: mask[:, w-1-i],  w, int(w * MAX_TRIM))

    # If an edge had a real cream margin, also step past the ink frame line.
    fy, fx = int(h * FRAME_INSET), int(w * FRAME_INSET)
    if top:    top    = min(top + fy, int(h * MAX_TRIM))
    if bottom: bottom = min(bottom + fy, int(h * MAX_TRIM))
    if left:   left   = min(left + fx, int(w * MAX_TRIM))
    if right:  right  = min(right + fx, int(w * MAX_TRIM))

    if not (top or bottom or left or right):
        return None  # already full-bleed
    crop = im.crop((left, top, w - right, h - bottom))
    crop.save(path)
    return (left, top, right, bottom, crop.size)

def main():
    paths = [p for p in glob.glob(f"{ASSETS}/**/*.png", recursive=True) if PAGE_RE.search(p)]
    paths.sort()
    trimmed = 0
    for p in paths:
        r = trim_one(p)
        name = p.split("/")[-2]
        if r:
            trimmed += 1
            print(f"  trim {name}: L{r[0]} T{r[1]} R{r[2]} B{r[3]} -> {r[4]}")
        else:
            print(f"  skip {name}: already full-bleed")
    print(f"\n{trimmed}/{len(paths)} images trimmed.")

if __name__ == "__main__":
    main()
